import 'package:caderneta/dominio/caderneta.dart';
import 'package:caderneta/dominio/cobranca.dart';
import 'package:caderneta/dominio/dinheiro.dart';
import 'package:caderneta/dominio/pix.dart';
import 'package:flutter_test/flutter_test.dart';

final hoje = DateTime(2026, 11, 10);
const cida = Cliente(id: 'cida', nome: 'Aparecida Souza', telefone: '73988887777', limite: 30000, diaDoAcerto: 5);
const ze = Cliente(id: 'ze', nome: 'José Carlos');

var _n = 0;
Lancamento compra(Cliente c, int valor, DateTime quando, [String descricao = '']) =>
    Lancamento(id: 'l${_n++}', clienteId: c.id, tipo: Tipo.compra, valor: valor, quando: quando, descricao: descricao);
Lancamento pagamento(Cliente c, int valor, DateTime quando) =>
    Lancamento(id: 'l${_n++}', clienteId: c.id, tipo: Tipo.pagamento, valor: valor, quando: quando);

void main() {
  group('dinheiro', () {
    test('escreve reais com milhar e centavos', () {
      expect(reais(0), 'R\$ 0,00');
      expect(reais(2350), 'R\$ 23,50');
      expect(reais(123456789), 'R\$ 1.234.567,89');
      expect(reais(-1000), '-R\$ 10,00');
    });

    test('lê o valor digitado', () {
      expect(centavosDe('23,5'), 2350);
      expect(centavosDe('1.234,56'), 123456);
      expect(centavosDe('7'), 700);
      expect(centavosDe('R\$ 12,05'), 1205);
      expect(centavosDe('12,345'), isNull);
      expect(centavosDe('abc'), isNull);
      expect(centavosDe(''), isNull);
    });
  });

  group('situação do cliente', () {
    test('o pagamento abate as compras mais antigas primeiro', () {
      final s = situacaoDe(cida, [
        compra(cida, 5000, DateTime(2026, 9, 20), 'arroz e feijão'),
        compra(cida, 3000, DateTime(2026, 10, 2), 'gás'),
        compra(cida, 2000, DateTime(2026, 10, 25), 'pão e leite'),
        pagamento(cida, 6000, DateTime(2026, 10, 5)),
      ], hoje);
      expect(s.saldo, 4000);
      expect(s.emAberto.map((a) => (a.compra.descricao, a.falta)), [('gás', 2000), ('pão e leite', 2000)]);
    });

    test('compra vence no dia do acerto do mês seguinte, e o atraso conta da mais antiga', () {
      final s = situacaoDe(cida, [compra(cida, 3000, DateTime(2026, 10, 2)), compra(cida, 2000, DateTime(2026, 10, 25))], hoje);
      expect(s.proximoVencimento, DateTime(2026, 11, 5));
      expect(s.diasDeAtraso, 5);
      expect(s.emDia, isFalse);
    });

    test('sem dia do acerto, vence 30 dias depois da compra', () {
      expect(vencimentoDa(DateTime(2026, 10, 20, 18, 30), null), DateTime(2026, 11, 19));
      expect(vencimentoDa(DateTime(2026, 12, 15), 10), DateTime(2027, 1, 10));
      expect(situacaoDe(ze, [compra(ze, 1500, DateTime(2026, 10, 20))], hoje).diasDeAtraso, 0);
    });

    test('lançamento riscado sai da conta', () {
      final errada = compra(cida, 99900, DateTime(2026, 11, 1));
      expect(situacaoDe(cida, [errada.riscar()], hoje).saldo, 0);
    });

    test('pagamento a mais vira crédito do cliente', () {
      final s = situacaoDe(ze, [compra(ze, 1000, DateTime(2026, 11, 1)), pagamento(ze, 1500, DateTime(2026, 11, 2))], hoje);
      expect(s.saldo, -500);
      expect(s.emAberto, isEmpty);
    });

    test('avisa quando a compra passa do limite', () {
      final s = situacaoDe(cida, [compra(cida, 25000, DateTime(2026, 11, 1))], hoje);
      expect(avisoDaCompra(s, 5000), isNull);
      expect(avisoDaCompra(s, 8000), 'Com esta compra, a conta vai a R\$ 330,00 e passa R\$ 30,00 do limite de R\$ 300,00.');
      expect(avisoDaCompra(situacaoDe(ze, const [], hoje), 999999), isNull);
    });
  });

  test('cobra primeiro o mais atrasado, depois o vencimento mais próximo, e quem não deve por último', () {
    const ana = Cliente(id: 'ana', nome: 'Ana', diaDoAcerto: 20);
    const bia = Cliente(id: 'bia', nome: 'Bia');
    const caio = Cliente(id: 'caio', nome: 'Caio');
    final lancamentos = [
      compra(cida, 3000, DateTime(2026, 10, 2)), // venceu 05/11: 5 dias
      compra(ze, 1000, DateTime(2026, 9, 20)), // venceu 20/10: 21 dias
      compra(ana, 2000, DateTime(2026, 10, 10)), // vence 20/11
      compra(bia, 2000, DateTime(2026, 10, 15)), // vence 14/11
    ];
    final ordem = ordemDeCobranca([cida, ze, ana, bia, caio].map((c) => (c, situacaoDe(c, lancamentos, hoje))));
    expect(ordem.map((c) => c.$1.id), ['ze', 'cida', 'bia', 'ana', 'caio']);
  });

  group('Pix copia e cola', () {
    test('confere com o exemplo do manual do Banco Central', () {
      expect(
        pixCopiaECola(chave: '123e4567-e12b-12d1-a456-426655440000', nome: 'Fulano de Tal', cidade: 'BRASILIA'),
        '00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-4266554400005204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***63041D3D',
      );
    });

    test('leva o valor, tira os acentos e corta nome e cidade no tamanho do padrão', () {
      final codigo = pixCopiaECola(chave: 'pix@mercadinho.exemplo', nome: 'Mercadinho Dois Irmãos da Conceição', cidade: 'São José da Vitória', valor: 4000, txid: 'CAD-CIDA-261110');
      expect(codigo, contains('540540.00'));
      expect(codigo, contains('5925Mercadinho Dois Irmaos da'));
      expect(codigo, contains('6015Sao Jose da Vit'));
      expect(codigo, contains('62170513CADCIDA261110'));
      expect(codigo.substring(codigo.length - 4), crc16(codigo.substring(0, codigo.length - 4)));
    });

    test('calcula o CRC-16/CCITT-FALSE', () {
      expect(crc16('123456789'), '29B1');
    });
  });

  group('cobrança', () {
    const loja = Loja(nome: 'Mercadinho Dois Irmãos', cidade: 'Itabuna', chavePix: 'pix@mercadinho.exemplo');

    test('a mensagem diz quanto, o que venceu e traz o Pix com o valor', () {
      final s = situacaoDe(cida, [compra(cida, 3000, DateTime(2026, 10, 2), 'gás'), compra(cida, 1000, DateTime(2026, 10, 25))], hoje);
      final mensagem = mensagemDeCobranca(loja: loja, cliente: cida, situacao: s, hoje: hoje);
      expect(mensagem, startsWith('Oi, Aparecida! Aqui é do Mercadinho Dois Irmãos.\nSua conta do fiado está em R\$ 40,00, e a parte que venceu em 05/11 ainda está aberta.'));
      expect(mensagem, contains('• 02/10: gás, R\$ 30,00'));
      expect(mensagem, contains('• 25/10: compra, R\$ 10,00'));
      expect(mensagem, contains('540540.00'));
    });

    test('chama o cliente pelo primeiro nome, com o tratamento junto', () {
      expect(comoChamar('Aparecida Souza'), 'Aparecida');
      expect(comoChamar('Dona Cida'), 'Dona Cida');
      expect(comoChamar('Seu Zé da oficina'), 'Seu Zé');
      expect(comoChamar('Juninho'), 'Juninho');
    });

    test('o link abre a conversa do cliente com o DDI do Brasil', () {
      final link = linkDoWhatsApp('(73) 98888-7777', 'Oi & tchau');
      expect(link.toString(), 'https://wa.me/5573988887777?text=Oi+%26+tchau');
      expect(linkDoWhatsApp('', 'x').path, '/');
    });
  });
}
