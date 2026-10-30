import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/archivo_validador.dart';
import '../models/documento.dart';
import '../models/expediente.dart';

class ArchivoRepository {
  ArchivoRepository(this.db, this.storage, this.auth);
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get _expedientes =>
      db.collection('expedientes');
  CollectionReference<Map<String, dynamic>> get _publicos =>
      db.collection('public_expedientes');

  Stream<List<Expediente>> listarExpedientes({required bool invitado}) =>
      (invitado ? _publicos : _expedientes)
          .orderBy('fechaCreacion', descending: true)
          .snapshots()
          .map((pagina) => pagina.docs.map(Expediente.desdeDocumento).toList());

  Stream<List<Documento>> listarDocumentos(
    String expedienteId, {
    required bool invitado,
  }) => (invitado ? _publicos : _expedientes)
      .doc(expedienteId)
      .collection('documentos')
      .orderBy('fechaCreacion', descending: true)
      .snapshots()
      .map((pagina) => pagina.docs.map(Documento.desdeDocumento).toList());

  Future<void> crearExpediente({
    required String tipoOperacion,
    required String descripcion,
  }) async {
    final ano = DateTime.now().year;
    final contadorRef = db.collection('contadores').doc('expedientes_$ano');
    final expedienteRef = _expedientes.doc();
    await db.runTransaction((transaccion) async {
      final contador = await transaccion.get(contadorRef);
      final siguiente = ((contador.data()?['ultimo'] as int?) ?? 0) + 1;
      transaccion.set(contadorRef, {'ultimo': siguiente});
      transaccion.set(expedienteRef, {
        'codigo': 'EXP-$ano-${siguiente.toString().padLeft(4, '0')}',
        'tipoOperacion': tipoOperacion,
        'descripcion': descripcion.trim(),
        'estado': 'abierto',
        'observaciones': '',
        'visibleParaInvitados': false,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> publicarExpediente(Expediente expediente, bool publicar) async {
    final privado = _expedientes.doc(expediente.id);
    final publico = _publicos.doc(expediente.id);
    final lote = db.batch();
    lote.update(privado, {
      'visibleParaInvitados': publicar,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
    if (publicar) {
      lote.set(publico, {
        'codigo': expediente.codigo,
        'tipoOperacion': expediente.tipoOperacion,
        'descripcion': expediente.descripcion,
        'estado': expediente.estado,
        'visibleParaInvitados': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } else {
      lote.delete(publico);
    }
    await lote.commit();
  }

  Future<void> subirDocumento({
    required String expedienteId,
    required String nombre,
    required String tipoDocumento,
    required Uint8List bytes,
  }) async {
    final mime = ArchivoValidador.validar(nombre, bytes);
    final extension = nombre.split('.').last.toLowerCase();
    final nombreSeguro = nombre.split(RegExp(r'[/\\]')).last;
    final documentoRef = _expedientes
        .doc(expedienteId)
        .collection('documentos')
        .doc();
    final versionRef = documentoRef.collection('versiones').doc();
    final ruta =
        'expedientes/$expedienteId/documentos/${documentoRef.id}'
        '/versiones/${versionRef.id}/archivo.$extension';
    final archivoRef = storage.ref(ruta);
    await archivoRef.putData(bytes, SettableMetadata(contentType: mime));
    try {
      final lote = db.batch();
      lote.set(documentoRef, {
        'expedienteId': expedienteId,
        'nombreOriginal': nombreSeguro,
        'nombreBusqueda': nombreSeguro.toLowerCase(),
        'tipoDocumento': tipoDocumento,
        'estadoRevision': 'pendiente',
        'visibleParaInvitados': false,
        'versionActualId': versionRef.id,
        'storagePath': ruta,
        'tipoMime': mime,
        'creadoPor': auth.currentUser!.uid,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      lote.set(versionRef, {
        'numeroVersion': 1,
        'storagePath': ruta,
        'tipoMime': mime,
        'tamanoBytes': bytes.length,
        'subidoPor': auth.currentUser!.uid,
        'fechaCarga': FieldValue.serverTimestamp(),
        'observaciones': '',
      });
      await lote.commit();
    } catch (_) {
      try {
        await archivoRef.delete();
      } catch (_) {
        // La limpieza se puede repetir desde una herramienta administrativa.
      }
      rethrow;
    }
  }

  Future<void> publicarDocumento(
    String expedienteId,
    Documento documento,
    bool publicar,
  ) async {
    if (publicar && !(await _publicos.doc(expedienteId).get()).exists) {
      throw StateError('Publica primero el expediente.');
    }
    final privado = _expedientes
        .doc(expedienteId)
        .collection('documentos')
        .doc(documento.id);
    final publico = _publicos
        .doc(expedienteId)
        .collection('documentos')
        .doc(documento.id);
    final lote = db.batch();
    lote.update(privado, {
      'visibleParaInvitados': publicar,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
    if (publicar) {
      lote.set(publico, {
        'nombreOriginal': documento.nombreOriginal,
        'nombreBusqueda': documento.nombreOriginal.toLowerCase(),
        'tipoDocumento': documento.tipoDocumento,
        'storagePath': documento.storagePath,
        'tipoMime': documento.tipoMime,
        'versionActualId': documento.storagePath.split('/')[5],
        'nombreArchivo': documento.storagePath.split('/').last,
        'visibleParaInvitados': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } else {
      lote.delete(publico);
    }
    await lote.commit();
  }

  Future<Uint8List> obtenerArchivo(Documento documento) async {
    if (documento.storagePath.isEmpty) {
      throw StateError('El documento no tiene archivo asociado.');
    }
    final datos = await storage
        .ref(documento.storagePath)
        .getData(ArchivoValidador.tamanoMaximo);
    if (datos == null) throw StateError('El archivo no está disponible.');
    return datos;
  }
}
