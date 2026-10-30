import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccesoService {
  AccesoService(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  Future<void> iniciarAdministrador(String correo, String clave) async {
    await auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: clave,
    );
  }

  Future<void> registrarAdministrador(String correo, String clave) async {
    final administrador = auth.currentUser;
    if (administrador == null || administrador.isAnonymous) {
      throw StateError(
        'Inicia sesión como administrador para registrar cuentas.',
      );
    }
    final token = await administrador.getIdTokenResult(true);
    final autorizado =
        token.claims?['admin'] == true ||
        (await db.collection('administradores').doc(administrador.uid).get())
                .data()?['rol'] ==
            'admin';
    if (!autorizado) {
      throw StateError('Esta cuenta no tiene autorización administrativa.');
    }

    // Una app de Firebase secundaria evita cerrar la sesión del administrador.
    final appRegistro = await Firebase.initializeApp(
      name: 'registro-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final authRegistro = FirebaseAuth.instanceFor(app: appRegistro);
    User? nuevoUsuario;
    try {
      final credencial = await authRegistro.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: clave,
      );
      nuevoUsuario = credencial.user;
      if (nuevoUsuario == null) {
        throw StateError('Firebase no devolvió la cuenta creada.');
      }
      await db.collection('administradores').doc(nuevoUsuario.uid).set({
        'correo': correo.trim().toLowerCase(),
        'rol': 'admin',
        'creadoPor': administrador.uid,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (nuevoUsuario != null) {
        try {
          await nuevoUsuario.delete();
        } catch (_) {
          throw StateError(
            'La cuenta se creó, pero no se pudo autorizar ni revertir. '
            'Revisa el usuario ${nuevoUsuario.uid} en Firebase Authentication.',
          );
        }
      }
      rethrow;
    } finally {
      await appRegistro.delete();
    }
  }

  Future<void> recuperarClave(String correo) async {
    if (correo.trim().isEmpty) {
      throw const FormatException('Escribe tu correo electrónico primero.');
    }
    await auth.sendPasswordResetEmail(email: correo.trim());
  }

  Future<void> autenticarInvitado() async {
    if (auth.currentUser?.isAnonymous != true) {
      await auth.signInAnonymously();
    }
  }

  Future<void> registrarInvitado() async {
    final usuario = auth.currentUser;
    if (usuario == null || !usuario.isAnonymous) {
      throw StateError('No existe una sesión de invitado.');
    }
    final preferencias = await SharedPreferences.getInstance();
    var instalacion = preferencias.getString('installationId');
    if (instalacion == null) {
      final aleatorio = Random.secure();
      final bytes = List<int>.generate(18, (_) => aleatorio.nextInt(256));
      instalacion = base64UrlEncode(bytes).replaceAll('=', '');
      await preferencias.setString('installationId', instalacion);
    }
    final plataforma = kIsWeb ? 'web' : 'android';
    final ref = db.collection('registros_invitados').doc(usuario.uid);
    await db.runTransaction((transaccion) async {
      final actual = await transaccion.get(ref);
      if (actual.exists) {
        transaccion.update(ref, {
          'fechaUltimoAcceso': FieldValue.serverTimestamp(),
          'cantidadAccesos': FieldValue.increment(1),
        });
      } else {
        transaccion.set(ref, {
          'guestUid': usuario.uid,
          'installationId': instalacion,
          'plataforma': plataforma,
          'fechaPrimerAcceso': FieldValue.serverTimestamp(),
          'fechaUltimoAcceso': FieldValue.serverTimestamp(),
          'cantidadAccesos': 1,
          'tipoAcceso': 'invitado',
        });
      }
    });
  }
}
