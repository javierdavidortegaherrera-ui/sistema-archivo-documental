import 'dart:typed_data';

import 'package:archivo_documental_aduanero/core/archivo_validador.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta PDF por extensión y firma', () {
    final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);
    expect(ArchivoValidador.validar('ejemplo.pdf', bytes), 'application/pdf');
  });

  test('rechaza extensión disfrazada y archivos vacíos', () {
    final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);
    expect(
      () => ArchivoValidador.validar('ejemplo.png', bytes),
      throwsFormatException,
    );
    expect(
      () => ArchivoValidador.validar('vacio.pdf', Uint8List(0)),
      throwsFormatException,
    );
  });

  test('rechaza archivos mayores a 10 MB', () {
    final bytes = Uint8List(ArchivoValidador.tamanoMaximo + 1);
    expect(
      () => ArchivoValidador.validar('grande.pdf', bytes),
      throwsFormatException,
    );
  });
}
