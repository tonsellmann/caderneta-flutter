// Dinheiro em centavos, sempre inteiro: R$ 23,50 é 2350. Conta de fiado não pode perder um
// centavo em arredondamento de ponto flutuante.

/// "R$ 1.234,56". Valor negativo sai com o sinal antes: "-R$ 10,00".
String reais(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final inteiro = (absoluto ~/ 100).toString();
  final resto = (absoluto % 100).toString().padLeft(2, '0');
  final milhares = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) milhares.write('.');
    milhares.write(inteiro[i]);
  }
  return '${negativo ? '-' : ''}R\$ $milhares,$resto';
}

/// O que se digita no teclado do app ("23,5", "1.234,56", "7") em centavos; null se não for valor.
int? centavosDe(String texto) {
  final limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '');
  if (!RegExp(r'^\d{1,7}(,\d{0,2})?$').hasMatch(limpo)) return null;
  final partes = limpo.split(',');
  final reaisInteiros = int.parse(partes[0]);
  final fracao = partes.length > 1 ? partes[1].padRight(2, '0') : '00';
  return reaisInteiros * 100 + int.parse(fracao);
}

/// "23.50": o formato do valor no código Pix.
String decimalComPonto(int centavos) => '${centavos ~/ 100}.${(centavos % 100).toString().padLeft(2, '0')}';
