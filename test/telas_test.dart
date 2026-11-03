import 'package:caderneta/dados/exemplo.dart';
import 'package:caderneta/dados/repositorio.dart';
import 'package:caderneta/dominio/caderneta.dart';
import 'package:caderneta/estado/caderno.dart';
import 'package:caderneta/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final hoje = DateTime(2026, 11, 10, 9);

Future<(Caderno, RepositorioNaMemoria)> abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repositorio = RepositorioNaMemoria(cadernoDeExemplo(hoje));
  final caderno = Caderno(repositorio: repositorio, relogio: () => hoje);
  await caderno.carregar();
  await tester.pumpWidget(CadernetaApp(caderno: caderno));
  await tester.pumpAndSettle();
  return (caderno, repositorio);
}

/// Como quem usa: rola a lista até o cliente sair de baixo do botão "Anotar fiado" e toca.
Future<void> abrirCliente(WidgetTester tester, String nome) async {
  await tester.scrollUntilVisible(find.text(nome), 80, scrollable: find.byType(Scrollable).first);
  final altura = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  if (tester.getCenter(find.text(nome)).dy > altura - 120) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(nome));
  await tester.pumpAndSettle();
}

Future<void> digitar(WidgetTester tester, String valor) async {
  for (final tecla in valor.split('')) {
    await tester.tap(find.descendant(of: find.byType(GridView), matching: find.text(tecla)));
    await tester.pump();
  }
}

void main() {
  testWidgets('a tela inicial mostra o total e cobra primeiro quem está mais atrasado', (tester) async {
    final (caderno, _) = await abrir(tester);
    expect(find.text('A receber no fiado'), findsOneWidget);
    expect(find.textContaining('atrasado'), findsWidgets);
    final nomes = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => ((t.title! as Text).data)).toList();
    expect(nomes.first, caderno.contas.first.$1.nome);
    expect(nomes.last, 'Tânia do salão'); // pagou tudo: vai para o fim
  });

  testWidgets('anotar um fiado pelo teclado soma na conta e salva no aparelho', (tester) async {
    final (caderno, repositorio) = await abrir(tester);
    final antes = caderno.situacao('marlene').saldo;
    await abrirCliente(tester, 'Marlene');
    await tester.tap(find.text('Fiado'));
    await tester.pumpAndSettle();
    await digitar(tester, '12,5');
    await tester.enterText(find.byType(TextField), 'café e açúcar');
    await tester.tap(find.text('Anotar R\$ 12,50'));
    await tester.pumpAndSettle();

    expect(caderno.situacao('marlene').saldo, antes + 1250);
    expect(repositorio.salvamentos, 1);
    expect(find.text('café e açúcar'), findsOneWidget);
  });

  testWidgets('avisa antes de anotar uma compra que passa do limite', (tester) async {
    await abrir(tester);
    await abrirCliente(tester, 'Dona Cida');
    await tester.tap(find.text('Fiado'));
    await tester.pumpAndSettle();
    await digitar(tester, '300');
    expect(find.textContaining('passa'), findsOneWidget);
    expect(find.textContaining('do limite de R\$ 300,00'), findsOneWidget);
  });

  testWidgets('o pagamento abate a conta, e o lançamento errado fica riscado', (tester) async {
    final semantica = tester.ensureSemantics();
    final (caderno, _) = await abrir(tester);
    final antes = caderno.situacao('ze').saldo;
    await abrirCliente(tester, 'Seu Zé da oficina');
    await tester.tap(find.text('Recebi'));
    await tester.pumpAndSettle();
    await digitar(tester, '50');
    await tester.tap(find.text('Recebi R\$ 50,00'));
    await tester.pumpAndSettle();
    expect(caderno.situacao('ze').saldo, antes - 5000);

    await tester.scrollUntilVisible(find.text('pagou').first, 80, scrollable: find.byType(Scrollable).first);
    await tester.longPress(find.bySemanticsLabel(RegExp(r'pagou, R\$ 50,00$')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riscar'));
    await tester.pumpAndSettle();
    expect(caderno.situacao('ze').saldo, antes);
    expect(caderno.historico('ze').first.riscado, isTrue);
    semantica.dispose();
  });

  testWidgets('a cobrança traz o Pix com o valor da conta', (tester) async {
    final (caderno, _) = await abrir(tester);
    await abrirCliente(tester, 'Juninho');
    await tester.tap(find.text('Cobrar no WhatsApp, com Pix'));
    await tester.pumpAndSettle();
    final saldo = caderno.situacao('juninho').saldo;
    expect(find.text('Pix de R\$ 107,00'), findsOneWidget);
    expect(saldo, 10700);
    expect(find.textContaining('5406107.00'), findsOneWidget);
  });

  testWidgets('cadastra cliente novo e abre a página dele', (tester) async {
    final (caderno, _) = await abrir(tester);
    await tester.tap(find.byTooltip('Novo cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome ou apelido'), 'Rosa da feira');
    await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp com DDD (opcional)'), '123');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(find.text('Confira o número com DDD.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp com DDD (opcional)'), '(73) 99999-0000');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(caderno.clientes.last.telefone, '73999990000');
    expect(find.text('Nada anotado ainda.'), findsOneWidget);
  });

  test('o caderno salvo volta igual', () {
    final dados = cadernoDeExemplo(hoje);
    final lido = Dados.deJson(dados.paraJson());
    expect(lido.clientes.map((c) => c.nome), dados.clientes.map((c) => c.nome));
    expect(lido.lancamentos.length, dados.lancamentos.length);
    expect(lido.lancamentos.first.tipo, Tipo.compra);
    expect(lido.loja.chavePix, 'pix@mercadinho.exemplo');
  });
}
