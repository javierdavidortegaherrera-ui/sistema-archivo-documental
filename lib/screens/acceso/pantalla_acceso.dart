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

  void _volver() => setState(() {
    mostrarFormulario = false;
    error = null;
  });

  void _recuperarClave() {
    if (correo.text.trim().isEmpty || !correo.text.contains('@')) {
      setState(
        () => error = 'Escribe un correo válido para recuperar la contraseña.',
      );
      return;
    }
    _ejecutar(
      () => widget.acceso.recuperarClave(correo.text.trim()),
      exito: 'Si la cuenta existe, recibirás un correo de recuperación.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, espacio) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: espacio.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  if (mostrarFormulario)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: cargando ? null : _volver,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: _MarcaAcceso(compacta: mostrarFormulario),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (mostrarFormulario)
                          _formularioAdministrador(context)
                        else
                          _accionesIniciales(),
                        if (cargando)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: LinearProgressIndicator(),
                          ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          'Aviso de privacidad: se registra un identificador técnico de acceso '
                          'para fines demostrativos. Este prototipo no solicita datos personales al invitado.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _accionesIniciales() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: cargando
            ? null
            : () => setState(() {
                mostrarFormulario = true;
                error = null;
              }),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: const Text('Iniciar sesión como administrador'),
      ),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: cargando
            ? null
            : () => _ejecutar(widget.acceso.autenticarInvitado),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: const Text('Continuar como invitado'),
      ),
    ],
  );

  Widget _formularioAdministrador(BuildContext context) => Form(
    key: formulario,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acceso de administrador',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: correo,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
          validator: (valor) => valor == null || !valor.contains('@')
              ? 'Escribe un correo válido.'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: clave,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _iniciarSesion(),
          decoration: const InputDecoration(labelText: 'Contraseña'),
          validator: (valor) =>
              valor == null || valor.isEmpty ? 'Escribe tu contraseña.' : null,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: cargando ? null : _iniciarSesion,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Ingresar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: cargando ? null : _recuperarClave,
          child: const Text('Recuperar contraseña'),
        ),
      ],
    ),
  );

  void _iniciarSesion() {
    if (cargando || !formulario.currentState!.validate()) return;
    _ejecutar(
      () => widget.acceso.iniciarAdministrador(correo.text.trim(), clave.text),
    );
  }
}

class _MarcaAcceso extends StatelessWidget {
  const _MarcaAcceso({required this.compacta});
  final bool compacta;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: compacta ? 24 : 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/logo_aduanero.png',
            width: compacta ? 104 : 152,
            height: compacta ? 104 : 152,
          ),
        ),
        SizedBox(height: compacta ? 16 : 24),
        Text(
          'Archivo Aduanero',
          textAlign: TextAlign.center,
          style:
              (compacta
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.headlineLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Sistema de Archivo y Control Documental Aduanero',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
  );
}
