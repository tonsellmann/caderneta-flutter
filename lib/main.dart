import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dados/repositorio.dart';
import 'estado/caderno.dart';
import 'tela/inicio.dart';
import 'tela/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final caderno = Caderno(repositorio: RepositorioNoAparelho())..carregar();
  runApp(CadernetaApp(caderno: caderno));
}

class CadernetaApp extends StatelessWidget {
  const CadernetaApp({super.key, required this.caderno});

  final Caderno caderno;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caderneta',
      debugShowCheckedModeBanner: false,
      theme: temaDaCaderneta(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Inicio(caderno: caderno),
    );
  }
}
