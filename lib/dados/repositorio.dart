// Onde o caderno fica guardado: no próprio aparelho, em JSON. O mercadinho não depende de
// internet para anotar o fiado, e um caderno de bairro cabe folgado (centenas de clientes,
// alguns milhares de lançamentos).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/caderneta.dart';
import '../dominio/cobranca.dart';

class Dados {
  const Dados({required this.loja, required this.clientes, required this.lancamentos});

  final Loja loja;
  final List<Cliente> clientes;
  final List<Lancamento> lancamentos;

  String paraJson() => jsonEncode({
        'versao': 1,
        'loja': {'nome': loja.nome, 'cidade': loja.cidade, 'chavePix': loja.chavePix},
        'clientes': [for (final c in clientes) c.paraJson()],
        'lancamentos': [for (final l in lancamentos) l.paraJson()],
      });

  factory Dados.deJson(String texto) {
    final json = jsonDecode(texto) as Map<String, Object?>;
    final loja = json['loja']! as Map<String, Object?>;
    return Dados(
      loja: Loja(nome: loja['nome']! as String, cidade: loja['cidade']! as String, chavePix: (loja['chavePix'] as String?) ?? ''),
      clientes: [for (final c in json['clientes']! as List) Cliente.deJson((c as Map).cast<String, Object?>())],
      lancamentos: [for (final l in json['lancamentos']! as List) Lancamento.deJson((l as Map).cast<String, Object?>())],
    );
  }
}

abstract interface class Repositorio {
  /// Null quando o caderno ainda está em branco.
  Future<Dados?> carregar();
  Future<void> salvar(Dados dados);
}

class RepositorioNoAparelho implements Repositorio {
  static const _chave = 'caderneta.v1';

  @override
  Future<Dados?> carregar() async {
    final texto = (await SharedPreferences.getInstance()).getString(_chave);
    return texto == null ? null : Dados.deJson(texto);
  }

  @override
  Future<void> salvar(Dados dados) async {
    await (await SharedPreferences.getInstance()).setString(_chave, dados.paraJson());
  }
}

class RepositorioNaMemoria implements Repositorio {
  RepositorioNaMemoria([this._dados]);

  Dados? _dados;
  int salvamentos = 0;

  @override
  Future<Dados?> carregar() async => _dados;

  @override
  Future<void> salvar(Dados dados) async {
    // Passa pelo JSON, como no aparelho: o teste pega o erro de serialização.
    _dados = Dados.deJson(dados.paraJson());
    salvamentos++;
  }
}
