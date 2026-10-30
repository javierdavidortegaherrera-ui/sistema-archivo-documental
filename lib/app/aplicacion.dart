import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../repositories/archivo_repository.dart';
import '../screens/acceso/pantalla_acceso.dart';
import '../screens/inicio/pantalla_inicio.dart';
import '../services/acceso_service.dart';

class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF0D3B99);
    final acceso = AccesoService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );
    final archivo = ArchivoRepository(
      FirebaseFirestore.instance,
      FirebaseStorage.instance,
      FirebaseAuth.instance,
    );
    return MaterialApp(
      title: 'Sistema de Archivo y Control Documental Aduanero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: azul),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, estado) {
          if (!estado.hasData &&
              estado.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final usuario = estado.data;
          if (usuario == null) return PantallaAcceso(acceso: acceso);
          return usuario.isAnonymous
              ? _EntradaInvitado(
                  key: ValueKey(usuario.uid),
                  acceso: acceso,
                  archivo: archivo,
                )
              : _EntradaAdministrador(
                  key: ValueKey(usuario.uid),
                  usuario: usuario,
                  archivo: archivo,
                );
        },
      ),
    );
  }
}

class _EntradaInvitado extends StatefulWidget {
  const _EntradaInvitado({
    super.key,
    required this.acceso,
    required this.archivo,
  });
  final AccesoService acceso;
  final ArchivoRepository archivo;

  @override
  State<_EntradaInvitado> createState() => _EntradaInvitadoState();
}

class _EntradaInvitadoState extends State<_EntradaInvitado> {
  late Future<void> registro = widget.acceso.registrarInvitado();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: registro,
    builder: (context, estado) {
      if (estado.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (estado.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo registrar el acceso del invitado.'),
                const SizedBox(height: 8),
                Text(estado.error.toString()),
                TextButton(
                  onPressed: () => setState(
                    () => registro = widget.acceso.registrarInvitado(),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }
      return PantallaInicio(archivo: widget.archivo, invitado: true);
    },
  );
}

class _EntradaAdministrador extends StatefulWidget {
  const _EntradaAdministrador({
    super.key,
    required this.usuario,
    required this.archivo,
  });
  final User usuario;
  final ArchivoRepository archivo;

  @override
  State<_EntradaAdministrador> createState() => _EntradaAdministradorState();
}

class _EntradaAdministradorState extends State<_EntradaAdministrador> {
  late final Future<bool> autorizado = _verificar();

  Future<bool> _verificar() async {
    final token = await widget.usuario.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: autorizado,
    builder: (context, estado) {
      if (estado.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (estado.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo verificar la autorización.'),
                Text(estado.error.toString()),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Volver al acceso'),
                ),
              ],
            ),
          ),
        );
      }
      if (estado.data != true) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Esta cuenta no tiene autorización administrativa.'),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Volver al acceso'),
                ),
              ],
            ),
          ),
        );
      }
      return PantallaInicio(archivo: widget.archivo, invitado: false);
    },
  );
}
