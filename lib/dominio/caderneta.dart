// O caderno de fiado: clientes, o que cada um comprou e pagou, quanto deve, o que venceu e quem
// cobrar primeiro. Puro: sem Flutter, sem armazenamento e sem relógio; quem chama passa "hoje".

import 'dinheiro.dart';

class Cliente {
  const Cliente({required this.id, required this.nome, this.telefone = '', this.limite, this.diaDoAcerto});

  final String id;
  final String nome;

  /// Só dígitos, com DDD: "73999990000".
  final String telefone;

  /// Até quanto a loja deixa o cliente dever, em centavos. Null: sem limite.
  final int? limite;

  /// Dia do mês em que o cliente acerta o que comprou no mês anterior (1 a 28). Null: 30 dias
  /// depois de cada compra.
  final int? diaDoAcerto;

  Cliente copiar({String? nome, String? telefone, int? Function()? limite, int? Function()? diaDoAcerto}) => Cliente(
        id: id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        limite: limite != null ? limite() : this.limite,
        diaDoAcerto: diaDoAcerto != null ? diaDoAcerto() : this.diaDoAcerto,
      );

  Map<String, Object?> paraJson() => {'id': id, 'nome': nome, 'telefone': telefone, 'limite': limite, 'diaDoAcerto': diaDoAcerto};

  factory Cliente.deJson(Map<String, Object?> json) => Cliente(
        id: json['id']! as String,
        nome: json['nome']! as String,
        telefone: (json['telefone'] as String?) ?? '',
        limite: json['limite'] as int?,
        diaDoAcerto: json['diaDoAcerto'] as int?,
      );
}

enum Tipo { compra, pagamento }

class Lancamento {
  const Lancamento({
    required this.id,
    required this.clienteId,
    required this.tipo,
    required this.valor,
    required this.quando,
    this.descricao = '',
    this.riscado = false,
  }) : assert(valor > 0);

  final String id;
  final String clienteId;
  final Tipo tipo;

  /// Em centavos, sempre positivo: o tipo diz se soma ou abate.
  final int valor;
  final DateTime quando;
  final String descricao;

  /// Lançamento errado não some do caderno: fica riscado, fora da conta, mas à vista.
  final bool riscado;

  Lancamento riscar() => Lancamento(id: id, clienteId: clienteId, tipo: tipo, valor: valor, quando: quando, descricao: descricao, riscado: true);

  Map<String, Object?> paraJson() => {
        'id': id,
        'clienteId': clienteId,
        'tipo': tipo.name,
        'valor': valor,
        'quando': quando.toIso8601String(),
        'descricao': descricao,
        'riscado': riscado,
      };

  factory Lancamento.deJson(Map<String, Object?> json) => Lancamento(
        id: json['id']! as String,
        clienteId: json['clienteId']! as String,
        tipo: Tipo.values.byName(json['tipo']! as String),
        valor: json['valor']! as int,
        quando: DateTime.parse(json['quando']! as String),
        descricao: (json['descricao'] as String?) ?? '',
        riscado: (json['riscado'] as bool?) ?? false,
      );
}

/// Uma compra que ainda não foi paga inteira.
class CompraEmAberto {
  const CompraEmAberto({required this.compra, required this.falta, required this.vencimento});

  final Lancamento compra;
  final int falta;
  final DateTime vencimento;
}

class Situacao {
  const Situacao({required this.saldo, required this.emAberto, required this.diasDeAtraso, required this.limite});

  /// Quanto o cliente deve. Negativo: a loja deve a ele (pagou a mais).
  final int saldo;

  /// Compras com algum valor a pagar, da mais antiga para a mais nova.
  final List<CompraEmAberto> emAberto;

  /// Dias desde o vencimento da compra em aberto mais antiga; 0 se nada venceu.
  final int diasDeAtraso;
  final int? limite;

  bool get emDia => diasDeAtraso == 0;
  bool get passouDoLimite => limite != null && saldo > limite!;
  DateTime? get proximoVencimento => emAberto.isEmpty ? null : emAberto.first.vencimento;
}

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Quando vence uma compra: no dia do acerto do mês seguinte, ou 30 dias depois.
DateTime vencimentoDa(DateTime compra, int? diaDoAcerto) {
  final dia = _dia(compra);
  if (diaDoAcerto == null) return dia.add(const Duration(days: 30));
  return DateTime(dia.year, dia.month + 1, diaDoAcerto.clamp(1, 28));
}

/// O que o cliente deve e desde quando. Os pagamentos abatem as compras mais antigas primeiro,
/// como no caderno de papel: o que fica em aberto é sempre o mais recente.
Situacao situacaoDe(Cliente cliente, Iterable<Lancamento> lancamentos, DateTime hoje) {
  final validos = lancamentos.where((l) => l.clienteId == cliente.id && !l.riscado).toList()
    ..sort((a, b) => a.quando.compareTo(b.quando));
  int total(Tipo tipo) => validos.where((l) => l.tipo == tipo).fold<int>(0, (s, l) => s + l.valor);
  final pago = total(Tipo.pagamento);
  final comprado = total(Tipo.compra);

  var sobra = pago;
  final emAberto = <CompraEmAberto>[];
  for (final compra in validos.where((l) => l.tipo == Tipo.compra)) {
    final abatido = sobra >= compra.valor ? compra.valor : sobra;
    sobra -= abatido;
    if (abatido < compra.valor) {
      emAberto.add(CompraEmAberto(compra: compra, falta: compra.valor - abatido, vencimento: vencimentoDa(compra.quando, cliente.diaDoAcerto)));
    }
  }

  final atraso = emAberto.isEmpty ? 0 : _dia(hoje).difference(emAberto.first.vencimento).inDays;
  return Situacao(saldo: comprado - pago, emAberto: emAberto, diasDeAtraso: atraso > 0 ? atraso : 0, limite: cliente.limite);
}

/// Antes de anotar uma compra: o aviso, se ela fizer o cliente passar do limite.
String? avisoDaCompra(Situacao situacao, int valor) {
  final limite = situacao.limite;
  if (limite == null) return null;
  final depois = situacao.saldo + valor;
  if (depois <= limite) return null;
  return 'Com esta compra, a conta vai a ${reais(depois)} e passa ${reais(depois - limite)} do limite de ${reais(limite)}.';
}

/// Quem cobrar primeiro: os atrasados, do mais atrasado; depois quem tem conta aberta, do
/// vencimento mais próximo; quem não deve nada vai para o fim, em ordem alfabética.
List<(Cliente, Situacao)> ordemDeCobranca(Iterable<(Cliente, Situacao)> contas) {
  int grupo(Situacao s) => s.saldo <= 0 ? 2 : (s.emDia ? 1 : 0);
  return contas.toList()
    ..sort((a, b) {
      final porGrupo = grupo(a.$2).compareTo(grupo(b.$2));
      if (porGrupo != 0) return porGrupo;
      switch (grupo(a.$2)) {
        case 0:
          final porAtraso = b.$2.diasDeAtraso.compareTo(a.$2.diasDeAtraso);
          return porAtraso != 0 ? porAtraso : b.$2.saldo.compareTo(a.$2.saldo);
        case 1:
          return a.$2.proximoVencimento!.compareTo(b.$2.proximoVencimento!);
        default:
          return a.$1.nome.compareTo(b.$1.nome);
      }
    });
}
