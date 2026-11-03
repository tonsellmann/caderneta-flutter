// Cobrar: a mensagem pronta, o QR Code do Pix com o valor da conta e o botão que abre o WhatsApp.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dominio/cobranca.dart';
import '../dominio/dinheiro.dart';
import '../dominio/pix.dart';
import '../estado/caderno.dart';
import 'tema.dart';

Future<void> cobrar(BuildContext context, Caderno caderno, String clienteId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FolhaDeCobranca(caderno: caderno, clienteId: clienteId),
  );
}

class FolhaDeCobranca extends StatelessWidget {
  const FolhaDeCobranca({super.key, required this.caderno, required this.clienteId});

  final Caderno caderno;
  final String clienteId;

  @override
  Widget build(BuildContext context) {
    final cliente = caderno.cliente(clienteId);
    final situacao = caderno.situacao(clienteId);
    final hoje = caderno.hoje;
    final loja = caderno.loja;
    final mensagem = mensagemDeCobranca(loja: loja, cliente: cliente, situacao: situacao, hoje: hoje);
    final pix = pixCopiaECola(chave: loja.chavePix, nome: loja.nome, cidade: loja.cidade, valor: situacao.saldo, txid: txidDaCobranca(cliente, hoje));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, rolagem) => ListView(
        controller: rolagem,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Cobrar ${cliente.nome}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Cores.linha)),
              child: Column(children: [
                QrImageView(data: pix, size: 200, semanticsLabel: 'QR Code do Pix de ${reais(situacao.saldo)}'),
                Text('Pix de ${reais(situacao.saldo)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar o Pix copia e cola'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pix));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código Pix copiado.')));
            },
          ),
          const SizedBox(height: 16),
          const Text('Mensagem', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFE7F6E7), borderRadius: BorderRadius.circular(14)),
            child: SelectableText(mensagem, style: const TextStyle(fontSize: 14, height: 1.45)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Cores.pago),
            icon: const Icon(Icons.send),
            label: Text(cliente.telefone.isEmpty ? 'Abrir no WhatsApp e escolher o contato' : 'Abrir no WhatsApp'),
            onPressed: () => launchUrl(linkDoWhatsApp(cliente.telefone, mensagem), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}
