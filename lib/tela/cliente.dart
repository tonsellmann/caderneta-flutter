// A página do cliente: a conta, o limite e a folha do caderno com cada compra e pagamento, na
// letra de mão. Toque longo num lançamento risca o que foi anotado errado.

import 'package:flutter/material.dart';

import '../dominio/caderneta.dart';
import '../dominio/dinheiro.dart';
import '../estado/caderno.dart';
import 'anotar.dart';
import 'cobrar.dart';
import 'tema.dart';
import 'textos.dart';

class PaginaDoCliente extends StatelessWidget {
  const PaginaDoCliente({super.key, required this.caderno, required this.clienteId});

  final Caderno caderno;
  final String clienteId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: caderno,
      builder: (context, _) {
        final cliente = caderno.cliente(clienteId);
        final situacao = caderno.situacao(clienteId);
        final historico = caderno.historico(clienteId);
        return Scaffold(
          appBar: AppBar(title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              _Conta(cliente: cliente, situacao: situacao, hoje: caderno.hoje),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => anotar(context, caderno, clienteId, Tipo.compra),
                    icon: const Icon(Icons.add),
                    label: const Text('Fiado'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Cores.pago),
                    onPressed: situacao.saldo > 0 ? () => anotar(context, caderno, clienteId, Tipo.pagamento) : null,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Recebi'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: situacao.saldo > 0 ? () => cobrar(context, caderno, clienteId) : null,
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Cobrar no WhatsApp, com Pix'),
              ),
              const SizedBox(height: 20),
              _FolhaDoCaderno(historico: historico, aoRiscar: (l) => _confirmarRisco(context, l)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarRisco(BuildContext context, Lancamento lancamento) async {
    if (lancamento.riscado) return;
    final tipo = lancamento.tipo == Tipo.compra ? 'a compra' : 'o pagamento';
    final riscar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Riscar $tipo de ${reais(lancamento.valor)}?'),
        content: const Text('Fica no caderno, riscado, e sai da conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Cores.margemEscura), onPressed: () => Navigator.pop(context, true), child: const Text('Riscar')),
        ],
      ),
    );
    if (riscar == true) await caderno.riscar(lancamento.id);
  }
}

class _Conta extends StatelessWidget {
  const _Conta({required this.cliente, required this.situacao, required this.hoje});

  final Cliente cliente;
  final Situacao situacao;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = estado(situacao, hoje);
    final limite = cliente.limite;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Conta', style: TextStyle(color: Cores.tintaSuave, fontWeight: FontWeight.w600)),
          Text(reais(situacao.saldo > 0 ? situacao.saldo : 0), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          if (limite != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: limite == 0 ? 1 : (situacao.saldo / limite).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Cores.fundo,
                color: situacao.passouDoLimite ? Cores.margem : Cores.bic,
                semanticsLabel: 'Uso do limite',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              situacao.passouDoLimite ? 'Passou ${reais(situacao.saldo - limite)} do limite de ${reais(limite)}' : 'Limite de ${reais(limite)}',
              style: TextStyle(fontSize: 13, color: situacao.passouDoLimite ? Cores.margemEscura : Cores.tintaSuave, fontWeight: FontWeight.w600),
            ),
          ],
          if (cliente.diaDoAcerto != null) ...[
            const SizedBox(height: 6),
            Text('Acerta todo dia ${cliente.diaDoAcerto}', style: const TextStyle(fontSize: 13, color: Cores.tintaSuave)),
          ],
        ]),
      ),
    );
  }
}

/// Uma folha pautada com margem vermelha, como a do caderno do balcão.
class _FolhaDoCaderno extends StatelessWidget {
  const _FolhaDoCaderno({required this.historico, required this.aoRiscar});

  final List<Lancamento> historico;
  final void Function(Lancamento) aoRiscar;

  static const altura = 44.0;

  @override
  Widget build(BuildContext context) {
    if (historico.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('Nada anotado ainda.', textAlign: TextAlign.center));
    }
    return Container(
      decoration: BoxDecoration(color: Cores.papel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Cores.linha)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _Pauta(altura: altura),
        child: Column(children: [
          const SizedBox(height: altura, child: Padding(padding: EdgeInsets.only(left: 56, top: 12), child: Align(alignment: Alignment.centerLeft, child: Text('Caderno', style: TextStyle(fontFamily: letraDeMao, fontSize: 26, color: Cores.bic, fontWeight: FontWeight.w700))))),
          for (final l in historico) _LinhaDoCaderno(lancamento: l, altura: altura, aoRiscar: () => aoRiscar(l)),
          const SizedBox(height: altura),
        ]),
      ),
    );
  }
}

class _LinhaDoCaderno extends StatelessWidget {
  const _LinhaDoCaderno({required this.lancamento, required this.altura, required this.aoRiscar});

  final Lancamento lancamento;
  final double altura;
  final VoidCallback aoRiscar;

  @override
  Widget build(BuildContext context) {
    final pagamento = lancamento.tipo == Tipo.pagamento;
    final cor = lancamento.riscado ? Cores.tintaSuave : (pagamento ? Cores.pago : Cores.bic);
    final descricao = pagamento ? 'pagou' : (lancamento.descricao.isEmpty ? 'compra' : lancamento.descricao);
    final estilo = TextStyle(
      fontFamily: letraDeMao,
      fontSize: 23,
      height: 1,
      color: cor,
      decoration: lancamento.riscado ? TextDecoration.lineThrough : null,
      decorationColor: Cores.margemEscura,
      decorationThickness: 2,
    );
    // Uma linha do caderno é um item só para o leitor de tela, com o riscar como ação: o
    // excludeSemantics tira a do InkWell, então ela é declarada aqui.
    return Semantics(
      container: true,
      label: '${data(lancamento.quando)}, $descricao, ${reais(lancamento.valor)}${lancamento.riscado ? ', riscado' : ''}',
      onLongPressHint: lancamento.riscado ? null : 'riscar',
      onLongPress: lancamento.riscado ? null : aoRiscar,
      excludeSemantics: true,
      child: InkWell(
        onLongPress: lancamento.riscado ? null : aoRiscar,
        child: SizedBox(
          height: altura,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16, bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(width: 44, child: Text(data(lancamento.quando), style: estilo.copyWith(fontSize: 18, decoration: TextDecoration.none, color: Cores.tintaSuave))),
              const SizedBox(width: 12),
              Expanded(child: Text(descricao, overflow: TextOverflow.ellipsis, style: estilo)),
              Text('${pagamento ? '− ' : ''}${reais(lancamento.valor).replaceFirst('R\$ ', '')}', style: estilo.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Pauta extends CustomPainter {
  const _Pauta({required this.altura});

  final double altura;

  @override
  void paint(Canvas canvas, Size size) {
    final linha = Paint()
      ..color = Cores.pauta.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var y = altura; y < size.height; y += altura) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linha);
    }
    final margem = Paint()
      ..color = Cores.margem.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(56, 0), Offset(56, size.height), margem);
  }

  @override
  bool shouldRepaint(_Pauta antiga) => antiga.altura != altura;
}
