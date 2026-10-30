import 'package:cloud_firestore/cloud_firestore.dart';

class Documento {
  const Documento({
    required this.id,
    required this.nombreOriginal,
    required this.tipoDocumento,
    required this.storagePath,
    required this.tipoMime,
    required this.visibleParaInvitados,
    this.contenidoDemoBase64,
  });

  final String id;
  final String nombreOriginal;
  final String tipoDocumento;
  final String storagePath;
  final String tipoMime;
  final bool visibleParaInvitados;
  final String? contenidoDemoBase64;

  factory Documento.desdeDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final datos = doc.data() ?? {};
    return Documento(
      id: doc.id,
      nombreOriginal: datos['nombreOriginal'] as String? ?? '',
      tipoDocumento: datos['tipoDocumento'] as String? ?? 'Otro',
      storagePath: datos['storagePath'] as String? ?? '',
      tipoMime: datos['tipoMime'] as String? ?? '',
      visibleParaInvitados: datos['visibleParaInvitados'] as bool? ?? false,
      contenidoDemoBase64: datos['contenidoDemoBase64'] as String?,
    );
  }
}
