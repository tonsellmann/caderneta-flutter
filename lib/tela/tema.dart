// A cara do caderno de papel: tinta azul de caneta, pauta azul-clara, margem vermelha e
// marca-texto amarelo. Plus Jakarta Sans no app; Caveat, a letra de mão, nos lançamentos.

import 'package:flutter/material.dart';

abstract final class Cores {
  static const bic = Color(0xFF1E3A8A);
  static const bicEscuro = Color(0xFF172D6B);
  static const tinta = Color(0xFF141C2F);
  static const tintaSuave = Color(0xFF4B5670);
  static const pauta = Color(0xFF9DB7E0);
  static const margem = Color(0xFFE45B5B);
  static const margemEscura = Color(0xFFB83A3A);
  static const pago = Color(0xFF1B7D52);
  static const marcaTexto = Color(0xFFFFE45C);
  static const papel = Color(0xFFFFFFFF);
  static const fundo = Color(0xFFF3F5F9);
  static const linha = Color(0xFFDDE3EF);
}

const letraDeMao = 'Caveat';

ThemeData temaDaCaderneta() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.bic).copyWith(
    primary: Cores.bic,
    onPrimary: Colors.white,
    secondary: Cores.marcaTexto,
    onSecondary: Cores.tinta,
    error: Cores.margemEscura,
    surface: Cores.papel,
    onSurface: Cores.tinta,
    outlineVariant: Cores.linha,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: esquema, fontFamily: 'PlusJakartaSans');
  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    appBarTheme: const AppBarTheme(backgroundColor: Cores.fundo, foregroundColor: Cores.tinta, elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
    textTheme: base.textTheme.apply(bodyColor: Cores.tinta, displayColor: Cores.tinta),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'PlusJakartaSans')),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), foregroundColor: Cores.bic, side: const BorderSide(color: Cores.pauta)),
    ),
    // O botão de anotar é o marca-texto do caderno.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Cores.marcaTexto,
      foregroundColor: Cores.tinta,
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'PlusJakartaSans'),
    ),
    cardTheme: const CardThemeData(color: Cores.papel, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)), side: BorderSide(color: Cores.linha))),
    inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Cores.papel, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
  );
}
