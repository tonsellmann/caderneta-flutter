// O caderno de exemplo do Mercadinho Dois Irmãos (fictício), com datas contadas a partir de hoje
// para a demonstração sempre ter alguém atrasado, alguém em dia e alguém com o limite estourado.

import '../dominio/caderneta.dart';
import '../dominio/cobranca.dart';
import 'repositorio.dart';

Dados cadernoDeExemplo(DateTime hoje) {
  var n = 0;
  DateTime haDias(int dias, [int hora = 10]) => DateTime(hoje.year, hoje.month, hoje.day - dias, hora);
  Lancamento compra(String cliente, int valor, int dias, String descricao) =>
      Lancamento(id: 'ex${n++}', clienteId: cliente, tipo: Tipo.compra, valor: valor, quando: haDias(dias), descricao: descricao);
  Lancamento pagamento(String cliente, int valor, int dias) =>
      Lancamento(id: 'ex${n++}', clienteId: cliente, tipo: Tipo.pagamento, valor: valor, quando: haDias(dias, 17));

  return Dados(
    loja: const Loja(nome: 'Mercadinho Dois Irmãos', cidade: 'Itabuna', chavePix: 'pix@mercadinho.exemplo'),
    clientes: const [
      Cliente(id: 'cida', nome: 'Dona Cida', limite: 30000, diaDoAcerto: 5),
      Cliente(id: 'ze', nome: 'Seu Zé da oficina', limite: 50000),
      Cliente(id: 'marlene', nome: 'Marlene', diaDoAcerto: 10),
      Cliente(id: 'juninho', nome: 'Juninho', limite: 10000),
      Cliente(id: 'tania', nome: 'Tânia do salão', diaDoAcerto: 15),
      Cliente(id: 'raimundo', nome: 'Seu Raimundo'),
    ],
    lancamentos: [
      compra('cida', 4590, 52, 'arroz, feijão e óleo'),
      compra('cida', 12500, 40, 'botijão de gás'),
      pagamento('cida', 4590, 33),
      compra('cida', 3870, 18, 'pão, leite e café'),
      compra('cida', 2240, 6, 'frango'),
      compra('ze', 1850, 45, 'refrigerante e salgado'),
      compra('ze', 6200, 38, 'marmitas da semana'),
      pagamento('ze', 3000, 20),
      compra('ze', 4100, 9, 'marmitas'),
      compra('marlene', 2675, 12, 'verduras e ovos'),
      compra('marlene', 1890, 3, 'sabão e amaciante'),
      compra('juninho', 6400, 25, 'carvão e carne'),
      compra('juninho', 4300, 2, 'cerveja e gelo'),
      compra('tania', 3350, 28, 'material de limpeza'),
      pagamento('tania', 3350, 14),
      compra('raimundo', 990, 1, 'fumo'),
    ],
  );
}
