// O Pix "copia e cola" (BR Code) de valor fixo, no padrão EMV que o Banco Central define no
// Manual de Padrões para Iniciação do Pix. O cliente cola no app do banco, ou lê o QR Code, e o
// valor e o nome da loja já aparecem preenchidos.

import 'dinheiro.dart';

/// Cada campo é ID (2 dígitos) + tamanho (2 dígitos) + valor.
String _campo(String id, String valor) {
  if (valor.length > 99) throw ArgumentError('campo $id com ${valor.length} caracteres; o máximo é 99');
  return '$id${valor.length.toString().padLeft(2, '0')}$valor';
}

/// CRC-16/CCITT-FALSE (polinômio 0x1021, início 0xFFFF), em 4 dígitos hexadecimais maiúsculos.
String crc16(String texto) {
  var crc = 0xFFFF;
  for (final byte in texto.codeUnits) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

const _semAcento = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'ê': 'e', 'è': 'e', 'ë': 'e',
  'í': 'i', 'î': 'i', 'ì': 'i', 'ï': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ò': 'o', 'ö': 'o',
  'ú': 'u', 'û': 'u', 'ù': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// Nome e cidade vão sem acento e cortados no tamanho do padrão (25 e 15).
String _ascii(String texto, int maximo) {
  final buffer = StringBuffer();
  for (final letra in texto.split('')) {
    final minuscula = letra.toLowerCase();
    final trocada = _semAcento[minuscula];
    final semAcento = trocada == null ? letra : (letra == minuscula ? trocada : trocada.toUpperCase());
    if (RegExp(r'[A-Za-z0-9 .\-]').hasMatch(semAcento)) buffer.write(semAcento);
  }
  final limpo = buffer.toString().trim();
  return limpo.length > maximo ? limpo.substring(0, maximo).trim() : limpo;
}

/// O identificador da cobrança: até 25 letras e números. Sem um, o padrão pede "***".
String _txid(String? txid) {
  final limpo = (txid ?? '').replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (limpo.isEmpty) return '***';
  return limpo.length > 25 ? limpo.substring(0, 25) : limpo;
}

String pixCopiaECola({
  required String chave,
  required String nome,
  required String cidade,
  int? valor,
  String? txid,
}) {
  if (chave.trim().isEmpty) throw ArgumentError('a loja não tem chave Pix');
  final conta = _campo('00', 'br.gov.bcb.pix') + _campo('01', chave.trim());
  final semCrc = [
    _campo('00', '01'),
    _campo('26', conta),
    _campo('52', '0000'),
    _campo('53', '986'),
    if (valor != null && valor > 0) _campo('54', decimalComPonto(valor)),
    _campo('58', 'BR'),
    _campo('59', _ascii(nome, 25)),
    _campo('60', _ascii(cidade, 15)),
    _campo('62', _campo('05', _txid(txid))),
    // O CRC é calculado sobre tudo, incluindo o ID e o tamanho do próprio campo do CRC.
    '6304',
  ].join();
  return semCrc + crc16(semCrc);
}
