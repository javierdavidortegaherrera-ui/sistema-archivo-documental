import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/acceso_service.dart';

class PantallaAcceso extends StatefulWidget {
  const PantallaAcceso({super.key, required this.acceso});
  final AccesoService acceso;

  @override
  State<PantallaAcceso> createState() => _PantallaAccesoState();
}

class _PantallaAccesoState extends State<PantallaAcceso> {
  final formulario = GlobalKey<FormState>();
  final correo = TextEditingController();
  final clave = TextEditingController();
  bool mostrarFormulario = false;
  bool cargando = false;
  String? error;

  @override
  void dispose() {
    correo.dispose();
    clave.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(
    Future<void> Function() operacion, {
    String? exito,
  }) async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await operacion();
      if (mounted && exito != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(exito)));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = _mensajeAuth(e.code));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String _mensajeAuth(String codigo) => switch (codigo) {
    'invalid-email' => 'El correo electrónico no es válido.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Correo o contraseña incorrectos.',
    'network-request-failed' => 'No hay conexión. Inténtalo de nuevo.',
    'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
    _ => 'No se pudo completar el acceso ($codigo).',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo_aduanero.png', height: 150),
                    const SizedBox(height: 18),
                    Text(
                      'Sistema de Archivo y Control Documental Aduanero',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    if (mostrarFormulario)
                      Form(
                        key: formulario,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: correo,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                              ),
                              validator: (valor) =>
                                  valor == null || !valor.contains('@')
                                  ? 'Escribe un correo válido.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: clave,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                              ),
                              validator: (valor) =>
                                  valor == null || valor.isEmpty
                                  ? 'Escribe tu contraseña.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: cargando
                                  ? null
                                  : () {
                                      if (formulario.currentState!.validate()) {
                                        _ejecutar(
                                          () => widget.acceso
                                              .iniciarAdministrador(
                                                correo.text,
                                                clave.text,
                                              ),
                                        );
                                      }
                                    },
                              child: const Text('Ingresar como administrador'),
                            ),
                            TextButton(
                              onPressed: cargando
                                  ? null
                                  : () => _ejecutar(
                                      () => widget.acceso.recuperarClave(
                                        correo.text,
                                      ),
                                      exito: 'Si la cuenta existe, recibirás un correo de recuperación.',
                                    ),
                              child: const Text('Recuperar contraseña'),
                            ),
                            TextButton(
                              onPressed: cargando
                                  ? null
                                  : () => setState(
                                      () => mostrarFormulario = false,
                                    ),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: cargando
                              ? null
                              : () => setState(() => mostrarFormulario = true),
                          child: const Text(
                            'Iniciar sesión como administrador',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: cargando
                              ? null
                              : () =>
                                    _ejecutar(widget.acceso.autenticarInvitado),
                          child: const Text('Continuar como invitado'),
                        ),
                      ),
                    ],
                    if (cargando)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    const Text(
                      'Aviso de privacidad: se registra un identificador técnico de acceso '
                      'para fines demostrativos. Este prototipo no solicita datos personales al invitado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
