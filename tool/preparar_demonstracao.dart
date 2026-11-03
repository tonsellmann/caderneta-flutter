// Monta a demonstração do portfólio: a moldura (demonstracao/index.html) e, em app/, o build web.
// Deixa de fora o que o build JavaScript não carrega: os símbolos de depuração e os motores
// skwasm e wimp, que só servem ao build WebAssembly.
//
//   flutter build web --release --base-href /demos/caderneta-app/app/ --no-web-resources-cdn
//   dart run tool/preparar_demonstracao.dart ../Portfolio/public/demos/caderneta-app

import 'dart:io';

bool _fica(String caminho) {
  final nome = caminho.split(RegExp(r'[\\/]')).last;
  if (nome.endsWith('.symbols') || nome == '.last_build_id') return false;
  return !(nome.startsWith('skwasm') || nome.startsWith('wimp'));
}

void main(List<String> argumentos) {
  if (argumentos.length != 1) {
    stderr.writeln('Uso: dart run tool/preparar_demonstracao.dart <pasta de destino>');
    exit(1);
  }
  final build = Directory('build/web');
  if (!build.existsSync()) {
    stderr.writeln('Rode antes o flutter build web (veja o começo deste arquivo).');
    exit(1);
  }
  final destino = Directory(argumentos.single);
  if (destino.existsSync()) destino.deleteSync(recursive: true);
  final app = Directory('${destino.path}/app')..createSync(recursive: true);

  var copiados = 0;
  for (final entidade in build.listSync(recursive: true).whereType<File>()) {
    final relativo = entidade.path.substring(build.path.length + 1);
    if (!_fica(relativo)) continue;
    final alvo = File('${app.path}/$relativo')..parent.createSync(recursive: true);
    entidade.copySync(alvo.path);
    copiados++;
  }
  File('demonstracao/index.html').copySync('${destino.path}/index.html');
  stdout.writeln('Demonstração em ${destino.path}: moldura e $copiados arquivos do app.');
}
