import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/expediente.dart';
import '../../repositories/archivo_repository.dart';
import '../expedientes/panel_expedientes.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({
    super.key,
    required this.archivo,
    required this.invitado,
  });
  final ArchivoRepository archivo;
  final bool invitado;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int seccion = 0;
  Expediente? seleccionado;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= 850;
    final destinos = widget.invitado
        ? const [
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              label: 'Expedientes',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              label: 'Expedientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Visitas',
            ),
          ];
    final contenido = seleccionado != null
        ? PanelExpedientes(
            archivo: widget.archivo,
            invitado: widget.invitado,
            expediente: seleccionado,
            volver: () => setState(() => seleccionado = null),
          )
        : widget.invitado || seccion == 1
        ? PanelExpedientes(
            archivo: widget.archivo,
            invitado: widget.invitado,
            abrir: (expediente) => setState(() => seleccionado = expediente),
          )
        : seccion == 0
        ? _Dashboard(
            archivo: widget.archivo,
            irExpedientes: () => setState(() => seccion = 1),
          )
        : const _Visitas();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_aduanero.png',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                escritorio
                    ? 'Sistema de Archivo y Control Documental Aduanero'
                    : 'Archivo Aduanero',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: Text(
              escritorio ? 'Cerrar sesión' : 'Salir',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (escritorio)
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1100,
              selectedIndex: seccion,
              onDestinationSelected: (valor) => setState(() {
                seccion = valor;
                seleccionado = null;
              }),
              destinations: destinos
                  .map(
                    (destino) => NavigationRailDestination(
                      icon: destino.icon,
                      label: Text(destino.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: contenido),
        ],
      ),
      bottomNavigationBar: escritorio || widget.invitado
          ? null
          : NavigationBar(
              selectedIndex: seccion,
              onDestinationSelected: (valor) => setState(() {
                seccion = valor;
                seleccionado = null;
              }),
              destinations: destinos,
            ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.archivo, required this.irExpedientes});
  final ArchivoRepository archivo;
  final VoidCallback irExpedientes;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Expediente>>(
    stream: archivo.listarExpedientes(invitado: false),
    builder: (context, estado) {
      if (estado.hasError) return _EstadoError(error: estado.error.toString());
      if (!estado.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final expedientes = estado.data!;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Panel de administrador',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Repositorio documental de demostración'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metrica('Expedientes', '${expedientes.length}', Icons.folder),
              _Metrica(
                'Publicados',
                '${expedientes.where((e) => e.visibleParaInvitados).length}',
                Icons.visibility,
              ),
              _Metrica(
                'Privados',
                '${expedientes.where((e) => !e.visibleParaInvitados).length}',
                Icons.lock_outline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: irExpedientes,
              icon: const Icon(Icons.folder_open),
              label: const Text('Gestionar expedientes'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Los estados son internos del prototipo y no representan trámites oficiales.',
          ),
        ],
      );
    },
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica(this.titulo, this.valor, this.icono);
  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(valor, style: Theme.of(context).textTheme.headlineMedium),
            Text(titulo),
          ],
        ),
      ),
    ),
  );
}

class _Visitas extends StatelessWidget {
  const _Visitas();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('registros_invitados')
        .orderBy('fechaUltimoAcceso', descending: true)
        .limit(50)
        .snapshots(),
    builder: (context, estado) {
      if (estado.hasError) return _EstadoError(error: estado.error.toString());
      if (!estado.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final registros = estado.data!.docs;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Visitas de invitados',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text(
            'Identificadores técnicos; pueden cambiar al borrar datos locales.',
          ),
          const SizedBox(height: 12),
          if (registros.isEmpty)
            const Card(child: ListTile(title: Text('Aún no hay visitas.'))),
          ...registros.map((doc) {
            final datos = doc.data();
            final ultima = datos['fechaUltimoAcceso'] as Timestamp?;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(doc.id),
                subtitle: Text(
                  'Plataforma: ${datos['plataforma'] ?? '-'} · '
                  'Accesos: ${datos['cantidadAccesos'] ?? '-'} · '
                  'Último: ${ultima?.toDate().toLocal() ?? '-'}',
                ),
              ),
            );
          }),
        ],
      );
    },
  );
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No se pudieron cargar los datos. $error',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
