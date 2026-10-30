import 'dart:typed_data';

class ArchivoValidador {
  static const tamanoMaximo = 10 * 1024 * 1024;

  static String validar(String nombre, Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > tamanoMaximo) {
      throw const FormatException(
        'El archivo debe medir entre 1 byte y 10 MB.',
      );
    }
    final extension = nombre.split('.').last.toLowerCase();
    if (extension == 'pdf' &&
        bytes.length >= 5 &&
        String.fromCharCodes(bytes.take(5)) == '%PDF-') {
      return 'application/pdf';
    }
    if ((extension == 'jpg' || extension == 'jpeg') &&
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (extension == 'png' &&
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        String.fromCharCodes(bytes.sublist(1, 4)) == 'PNG' &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    throw const FormatException('Selecciona un PDF, JPG o PNG válido.');
  }
}
