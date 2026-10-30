import 'package:cloud_firestore/cloud_firestore.dart';

class Expediente {
  const Expediente({
    required this.id,
    required this.codigo,
    required this.tipoOperacion,
    required this.descripcion,
    required this.estado,
    required this.visibleParaInvitados,
  });

  final String id;
  final String codigo;
  final String tipoOperacion;
  final String descripcion;
  final String estado;
  final bool visibleParaInvitados;

  factory Expediente.desdeDocumento(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final datos = doc.data() ?? {};
    return Expediente(
      id: doc.id,
      codigo: datos['codigo'] as String? ?? '',
      tipoOperacion: datos['tipoOperacion'] as String? ?? '',
      descripcion: datos['descripcion'] as String? ?? '',
      estado: datos['estado'] as String? ?? 'abierto',
      visibleParaInvitados: datos['visibleParaInvitados'] as bool? ?? false,
    );
  }
}
