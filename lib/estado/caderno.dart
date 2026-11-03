// O estado do app: carrega o caderno, aplica cada anotação e salva em seguida. As telas só leem
// daqui e chamam os métodos; a conta é toda do domínio.

import 'package:flutter/foundation.dart';

import '../dados/exemplo.dart';
import '../dados/repositorio.dart';
import '../dominio/caderneta.dart';
import '../dominio/cobranca.dart';

class Caderno extends ChangeNotifier {
  Caderno({required this.repositorio, DateTime Function()? relogio}) : _relogio = relogio ?? DateTime.now;

  final Repositorio repositorio;
  final DateTime Function() _relogio;
  Dados? _dados;
  var _sequencia = 0;

  bool get carregado => _dados != null;
  DateTime get hoje => _relogio();
  Loja get loja => _dados!.loja;
  List<Cliente> get clientes => _dados!.clientes;
  List<Lancamento> get lancamentos => _dados!.lancamentos;

  /// Caderno em branco começa com o de exemplo: é um projeto conceito.
  Future<void> carregar() async {
    _dados = await repositorio.carregar() ?? cadernoDeExemplo(hoje);
    notifyListeners();
  }

  Cliente cliente(String id) => clientes.firstWhere((c) => c.id == id);
  Situacao situacao(String clienteId) => situacaoDe(cliente(clienteId), lancamentos, hoje);

  List<(Cliente, Situacao)> get contas => ordemDeCobranca(clientes.map((c) => (c, situacaoDe(c, lancamentos, hoje))));

  int get totalAReceber => contas.fold(0, (s, c) => s + (c.$2.saldo > 0 ? c.$2.saldo : 0));
  int get atrasados => contas.where((c) => c.$2.saldo > 0 && !c.$2.emDia).length;

  /// Lançamentos do cliente, do mais novo para o mais antigo, riscados incluídos.
  List<Lancamento> historico(String clienteId) =>
      lancamentos.where((l) => l.clienteId == clienteId).toList()..sort((a, b) => b.quando.compareTo(a.quando));

  String _novoId(String prefixo) => '$prefixo${_relogio().microsecondsSinceEpoch.toRadixString(36)}${(_sequencia++).toRadixString(36)}';

  Future<void> _guardar(Dados dados) async {
    _dados = dados;
    notifyListeners();
    await repositorio.salvar(dados);
  }

  Future<void> anotar(String clienteId, Tipo tipo, int valor, {String descricao = ''}) => _guardar(Dados(
        loja: loja,
        clientes: clientes,
        lancamentos: [
          ...lancamentos,
          Lancamento(id: _novoId('l'), clienteId: clienteId, tipo: tipo, valor: valor, quando: hoje, descricao: descricao.trim()),
        ],
      ));

  Future<void> riscar(String lancamentoId) => _guardar(Dados(
        loja: loja,
        clientes: clientes,
        lancamentos: [for (final l in lancamentos) l.id == lancamentoId ? l.riscar() : l],
      ));

  Future<Cliente> novoCliente({required String nome, String telefone = '', int? limite, int? diaDoAcerto}) async {
    final cliente = Cliente(id: _novoId('c'), nome: nome.trim(), telefone: telefone.replaceAll(RegExp(r'\D'), ''), limite: limite, diaDoAcerto: diaDoAcerto);
    await _guardar(Dados(loja: loja, clientes: [...clientes, cliente], lancamentos: lancamentos));
    return cliente;
  }
}
