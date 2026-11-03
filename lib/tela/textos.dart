// Como a situação de cada cliente aparece escrita nas telas.

import 'package:flutter/material.dart';

import '../dominio/caderneta.dart';
import '../dominio/dinheiro.dart';
import 'tema.dart';

String data(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String dias(int n) => n == 1 ? '1 dia' : '$n dias';

/// "Venceu há 5 dias", "Vence em 14/11", "Nada a dever", "Crédito de R$ 5,00".
(String, Color) estado(Situacao s, DateTime hoje) {
  if (s.saldo < 0) return ('Crédito de ${reais(-s.saldo)}', Cores.pago);
  if (s.saldo == 0) return ('Nada a dever', Cores.tintaSuave);
  if (s.diasDeAtraso > 0) return ('Venceu há ${dias(s.diasDeAtraso)}', Cores.margemEscura);
  final vencimento = s.proximoVencimento!;
  if (vencimento.year == hoje.year && vencimento.month == hoje.month && vencimento.day == hoje.day) return ('Vence hoje', Cores.bic);
  return ('Vence em ${data(vencimento)}', Cores.tintaSuave);
}

const _tratamentos = {'seu', 'dona', 'sr', 'sr.', 'sra', 'sra.', 'dr', 'dr.', 'tia', 'tio'};

/// A letra do avatar: "Dona Cida" é C, "Seu Zé da oficina" é Z.
String inicial(String nome) {
  final palavras = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final nomeProprio = palavras.firstWhere((p) => !_tratamentos.contains(p.toLowerCase()), orElse: () => palavras.isEmpty ? '?' : palavras.first);
  return nomeProprio.characters.first.toUpperCase();
}
