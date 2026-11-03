// Cadastro de cliente: só o nome é obrigatório. Limite e dia do acerto são o combinado no balcão.

import 'package:flutter/material.dart';

import '../dominio/dinheiro.dart';
import '../estado/caderno.dart';
import 'cliente.dart';

Future<void> abrirNovoCliente(BuildContext context, Caderno caderno) async {
  final id = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NovoCliente(caderno: caderno),
  );
  if (id != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PaginaDoCliente(caderno: caderno, clienteId: id)));
  }
}

class _NovoCliente extends StatefulWidget {
  const _NovoCliente({required this.caderno});

  final Caderno caderno;

  @override
  State<_NovoCliente> createState() => _NovoClienteState();
}

class _NovoClienteState extends State<_NovoCliente> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _limite = TextEditingController();
  int? _dia;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _limite.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final cliente = await widget.caderno.novoCliente(
      nome: _nome.text,
      telefone: _telefone.text,
      limite: _limite.text.trim().isEmpty ? null : centavosDe(_limite.text),
      diaDoAcerto: _dia,
    );
    if (mounted) Navigator.pop(context, cliente.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Novo cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nome,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome ou apelido'),
            validator: (v) => (v ?? '').trim().length < 2 ? 'Escreva o nome do cliente.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'WhatsApp com DDD (opcional)', hintText: '(73) 99999-0000'),
            validator: (v) {
              final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return digitos.isEmpty || digitos.length == 10 || digitos.length == 11 ? null : 'Confira o número com DDD.';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _limite,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Limite (opcional)', prefixText: 'R\$ '),
            validator: (v) => (v ?? '').trim().isEmpty || centavosDe(v!) != null ? null : 'Valor inválido.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _dia,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Quando acerta'),
            items: [
              const DropdownMenuItem(value: null, child: Text('30 dias depois de cada compra')),
              for (final dia in [1, 5, 10, 15, 20, 25]) DropdownMenuItem(value: dia, child: Text('Todo dia $dia')),
            ],
            onChanged: (dia) => setState(() => _dia = dia),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _salvar, child: const Text('Cadastrar')),
        ]),
      ),
    );
  }
}
