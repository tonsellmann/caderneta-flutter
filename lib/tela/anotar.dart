// Anotar uma compra ou um pagamento: teclado grande para o valor, porque o dono do mercadinho
// anota com o cliente esperando no balcão.

import 'package:flutter/material.dart';

import '../dominio/caderneta.dart';
import '../dominio/dinheiro.dart';
import '../estado/caderno.dart';
import 'tema.dart';

/// Pela tela inicial: primeiro escolhe o cliente, depois anota a compra.
Future<void> anotarParaAlguem(BuildContext context, Caderno caderno) async {
  final clientes = [...caderno.clientes]..sort((a, b) => a.nome.compareTo(b.nome));
  final escolhido = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Fiado para quem?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          for (final c in clientes) ListTile(title: Text(c.nome), onTap: () => Navigator.pop(context, c.id)),
        ]),
      ),
    ),
  );
  if (escolhido != null && context.mounted) await anotar(context, caderno, escolhido, Tipo.compra);
}

Future<void> anotar(BuildContext context, Caderno caderno, String clienteId, Tipo tipo) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FolhaDeAnotacao(caderno: caderno, clienteId: clienteId, tipo: tipo),
  );
}

class FolhaDeAnotacao extends StatefulWidget {
  const FolhaDeAnotacao({super.key, required this.caderno, required this.clienteId, required this.tipo});

  final Caderno caderno;
  final String clienteId;
  final Tipo tipo;

  @override
  State<FolhaDeAnotacao> createState() => _FolhaDeAnotacaoState();
}

class _FolhaDeAnotacaoState extends State<FolhaDeAnotacao> {
  var _digitado = '';
  final _descricao = TextEditingController();
  var _salvando = false;

  bool get _compra => widget.tipo == Tipo.compra;
  int? get _valor => _digitado.isEmpty ? null : centavosDe(_digitado);

  void _tecla(String tecla) {
    setState(() {
      if (tecla == '⌫') {
        if (_digitado.isNotEmpty) _digitado = _digitado.substring(0, _digitado.length - 1);
        return;
      }
      final proximo = _digitado + tecla;
      if (tecla == ',' && _digitado.contains(',')) return;
      if (centavosDe(proximo.endsWith(',') ? '${proximo}0' : proximo) == null) return;
      _digitado = proximo;
    });
  }

  Future<void> _salvar() async {
    final valor = _valor;
    if (valor == null || valor <= 0 || _salvando) return;
    setState(() => _salvando = true);
    await widget.caderno.anotar(widget.clienteId, widget.tipo, valor, descricao: _compra ? _descricao.text : '');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.caderno.cliente(widget.clienteId);
    final situacao = widget.caderno.situacao(widget.clienteId);
    final valor = _valor ?? 0;
    final aviso = _compra && valor > 0 ? avisoDaCompra(situacao, valor) : null;
    final cor = _compra ? Cores.bic : Cores.pago;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_compra ? 'Fiado de ${cliente.nome}' : 'Pagamento de ${cliente.nome}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          situacao.saldo > 0 ? 'Conta hoje: ${reais(situacao.saldo)}' : 'Sem conta aberta',
          style: const TextStyle(color: Cores.tintaSuave),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Valor',
          value: _digitado.isEmpty ? 'vazio' : reais(valor),
          child: Text(
            _digitado.isEmpty ? 'R\$ 0' : 'R\$ $_digitado',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: letraDeMao, fontSize: 56, fontWeight: FontWeight.w700, color: cor, height: 1.1),
          ),
        ),
        if (_compra) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _descricao,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'O que levou (opcional)', isDense: true),
          ),
        ],
        if (aviso != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Cores.marcaTexto.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Text(aviso, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        const SizedBox(height: 12),
        _Teclado(aoTocar: _tecla),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cor),
          onPressed: valor > 0 && !_salvando ? _salvar : null,
          child: Text(valor > 0 ? (_compra ? 'Anotar ${reais(valor)}' : 'Recebi ${reais(valor)}') : 'Digite o valor'),
        ),
      ]),
    );
  }
}

class _Teclado extends StatelessWidget {
  const _Teclado({required this.aoTocar});

  final void Function(String) aoTocar;

  @override
  Widget build(BuildContext context) {
    const teclas = ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final tecla in teclas)
          Material(
            color: Cores.fundo,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => aoTocar(tecla),
              child: Center(
                child: tecla == '⌫'
                    ? const Icon(Icons.backspace_outlined, semanticLabel: 'Apagar')
                    : Text(tecla, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }
}
