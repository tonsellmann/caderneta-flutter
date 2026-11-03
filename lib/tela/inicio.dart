// A primeira tela: quanto a loja tem a receber e a lista de quem cobrar, na ordem certa.

import 'package:flutter/material.dart';

import '../dominio/caderneta.dart';
import '../dominio/dinheiro.dart';
import '../estado/caderno.dart';
import 'anotar.dart';
import 'cliente.dart';
import 'novo_cliente.dart';
import 'tema.dart';
import 'textos.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key, required this.caderno});

  final Caderno caderno;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: caderno,
      builder: (context, _) {
        if (!caderno.carregado) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final contas = caderno.contas;
        return Scaffold(
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Caderneta', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(caderno.loja.nome, style: const TextStyle(fontSize: 13, color: Cores.tintaSuave)),
            ]),
            actions: [
              IconButton(
                tooltip: 'Novo cliente',
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () => abrirNovoCliente(context, caderno),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => anotarParaAlguem(context, caderno),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Anotar fiado'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              _Resumo(total: caderno.totalAReceber, atrasados: caderno.atrasados),
              const SizedBox(height: 20),
              const Text('QUEM COBRAR PRIMEIRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: Cores.tintaSuave)),
              const SizedBox(height: 8),
              Card(
                child: Column(children: [
                  for (final (i, conta) in contas.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    _LinhaDoCliente(cliente: conta.$1, situacao: conta.$2, caderno: caderno),
                  ],
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.total, required this.atrasados});

  final int total;
  final int atrasados;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Cores.bic, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('A receber no fiado', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(reais(total), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: atrasados > 0 ? Cores.marcaTexto : Colors.white24, borderRadius: BorderRadius.circular(8)),
          child: Text(
            atrasados == 0 ? 'Ninguém atrasado' : (atrasados == 1 ? '1 cliente atrasado' : '$atrasados clientes atrasados'),
            style: TextStyle(fontWeight: FontWeight.w700, color: atrasados > 0 ? Cores.tinta : Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _LinhaDoCliente extends StatelessWidget {
  const _LinhaDoCliente({required this.cliente, required this.situacao, required this.caderno});

  final Cliente cliente;
  final Situacao situacao;
  final Caderno caderno;

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = estado(situacao, caderno.hoje);
    final atrasado = situacao.saldo > 0 && !situacao.emDia;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: atrasado ? Cores.margem.withValues(alpha: 0.15) : Cores.fundo,
        foregroundColor: atrasado ? Cores.margemEscura : Cores.bic,
        child: Text(inicial(cliente.nome), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text.rich(TextSpan(children: [
        TextSpan(text: texto, style: TextStyle(color: cor, fontWeight: atrasado ? FontWeight.w700 : FontWeight.w500)),
        if (situacao.passouDoLimite) const TextSpan(text: ' · passou do limite', style: TextStyle(color: Cores.margemEscura, fontWeight: FontWeight.w700)),
      ])),
      trailing: Text(
        situacao.saldo > 0 ? reais(situacao.saldo) : '',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PaginaDoCliente(caderno: caderno, clienteId: cliente.id))),
    );
  }
}
