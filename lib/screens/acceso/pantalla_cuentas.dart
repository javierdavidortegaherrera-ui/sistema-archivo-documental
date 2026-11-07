import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/acceso_service.dart';
import '../../widgets/carga_esqueleto.dart';

class PantallaCuentas extends StatefulWidget {
  const PantallaCuentas({super.key, required this.acceso});
  final AccesoService acceso;

  @override
  State<PantallaCuentas> createState() => _PantallaCuentasState();
}

class _PantallaCuentasState extends State<PantallaCuentas> {
  final formulario = GlobalKey<FormState>();
  final correo = TextEditingController();
  final clave = TextEditingController();
  final confirmacion = TextEditingController();
  bool mostrarClave = false;
  bool cargando = false;
  String? error;

  @override
  void dispose() {
    correo.dispose();
    clave.dispose();
    confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!formulario.currentState!.validate()) return;
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await widget.acceso.registrarAdministrador(correo.text, clave.text);
      if (!mounted) return;
      formulario.currentState!.reset();
      correo.clear();
      clave.clear();
      confirmacion.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta de administrador registrada.')),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = _mensajeAuth(e.code));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String _mensajeAuth(String codigo) => switch (codigo) {
    'email-already-in-use' => 'Ese correo ya tiene una cuenta.',
    'invalid-email' => 'El correo electrónico no es válido.',
    'weak-password' => 'Usa una contraseña más segura.',
    'network-request-failed' => 'No hay conexión. Inténtalo de nuevo.',
    'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
    _ => 'No se pudo registrar la cuenta ($codigo).',
  };

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar cuenta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'La cuenta nueva tendrá acceso de administrador. '
                'Tu sesión actual permanecerá abierta.',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: correo,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                          ),
                          validator: (valor) {
                            final email = valor?.trim() ?? '';
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)
                                ? null
                                : 'Escribe un correo válido.';
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: clave,
                          obscureText: !mostrarClave,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            helperText: 'Mínimo 8 caracteres.',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => mostrarClave = !mostrarClave),
                              icon: Icon(
                                mostrarClave
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              tooltip: mostrarClave
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                            ),
                          ),
                          validator: (valor) =>
                              valor == null || valor.length < 8
                              ? 'Escribe al menos 8 caracteres.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmacion,
                          obscureText: !mostrarClave,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                          ),
                          validator: (valor) => valor != clave.text
                              ? 'Las contraseñas no coinciden.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: cargando ? null : _registrar,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Registrar cuenta'),
                        ),
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cuentas registradas desde la aplicación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('administradores')
                    .orderBy('fechaCreacion', descending: true)
                    .snapshots(),
                builder: (context, estado) {
                  if (estado.hasError) {
                    return const Text('No se pudo cargar la lista de cuentas.');
                  }
                  if (!estado.hasData) {
                    return const ListaEsqueleto(cantidad: 2);
                  }
                  final cuentas = estado.data!.docs;
                  if (cuentas.isEmpty) {
                    return const Card(
                      child: ListTile(
                        title: Text('Aún no hay cuentas registradas aquí.'),
                      ),
                    );
                  }
                  return Column(
                    children: cuentas
                        .map(
                          (doc) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              title: Text(
                                doc.data()['correo'] as String? ?? '',
                              ),
                              subtitle: const Text('Administrador'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
