// A mensagem de cobrança para o WhatsApp: educada, com o que está em aberto e o Pix pronto.

import 'caderneta.dart';
import 'dinheiro.dart';
import 'pix.dart';

class Loja {
  const Loja({required this.nome, required this.cidade, required this.chavePix});

  final String nome;
  final String cidade;
  final String chavePix;
}

String _data(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

const _tratamentos = {'seu', 'dona', 'sr.', 'sra.', 'dr.', 'dra.'};

/// Como chamar o cliente na mensagem: o primeiro nome, com o tratamento junto ("Dona Cida", "Seu Zé").
String comoChamar(String nome) {
  final palavras = nome.trim().split(RegExp(r'\s+'));
  if (palavras.length > 1 && _tratamentos.contains(palavras.first.toLowerCase())) return '${palavras[0]} ${palavras[1]}';
  return palavras.first;
}

/// O identificador da cobrança no Pix: o cliente e o dia, para a loja achar o pagamento no extrato.
String txidDaCobranca(Cliente cliente, DateTime hoje) =>
    'CAD${cliente.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase()}${hoje.year % 100}${hoje.month.toString().padLeft(2, '0')}${hoje.day.toString().padLeft(2, '0')}';

String mensagemDeCobranca({required Loja loja, required Cliente cliente, required Situacao situacao, required DateTime hoje}) {
  final linhas = <String>['Oi, ${comoChamar(cliente.nome)}! Aqui é do ${loja.nome}.'];
  if (situacao.diasDeAtraso > 0) {
    linhas.add('Sua conta do fiado está em ${reais(situacao.saldo)}, e a parte que venceu em ${_data(situacao.emAberto.first.vencimento)} ainda está aberta.');
  } else {
    linhas.add('Sua conta do fiado está em ${reais(situacao.saldo)}. Vence em ${_data(situacao.emAberto.first.vencimento)}.');
  }
  final mostradas = situacao.emAberto.take(5).toList();
  for (final aberta in mostradas) {
    final descricao = aberta.compra.descricao.isEmpty ? 'compra' : aberta.compra.descricao;
    final parcial = aberta.falta < aberta.compra.valor ? ' (falta ${reais(aberta.falta)})' : '';
    linhas.add('• ${_data(aberta.compra.quando)}: $descricao, ${reais(aberta.compra.valor)}$parcial');
  }
  if (situacao.emAberto.length > mostradas.length) {
    linhas.add('• e mais ${situacao.emAberto.length - mostradas.length} compras');
  }
  if (loja.chavePix.isNotEmpty) {
    linhas
      ..add('')
      ..add('Para pagar por Pix, copie o código abaixo e cole no app do banco:')
      ..add(pixCopiaECola(chave: loja.chavePix, nome: loja.nome, cidade: loja.cidade, valor: situacao.saldo, txid: txidDaCobranca(cliente, hoje)));
  }
  linhas
    ..add('')
    ..add('Obrigado pela confiança!');
  return linhas.join('\n');
}

/// O link que abre a conversa no WhatsApp com a mensagem escrita. Sem telefone, abre a escolha do contato.
Uri linkDoWhatsApp(String telefone, String mensagem) {
  final digitos = telefone.replaceAll(RegExp(r'\D'), '');
  final numero = digitos.isEmpty ? '' : (digitos.startsWith('55') && digitos.length > 11 ? digitos : '55$digitos');
  return Uri.https('wa.me', '/$numero', {'text': mensagem});
}
