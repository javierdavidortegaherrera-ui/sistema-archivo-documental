import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/archivo_validador.dart';
import '../../models/documento.dart';
import '../../models/expediente.dart';
import '../../repositories/archivo_repository.dart';

class PanelExpedientes extends StatefulWidget {
  const PanelExpedientes({
    super.key,
    required this.archivo,
    required this.invitado,
    this.expediente,
    this.abrir,
    this.volver,
  });
  final ArchivoRepository archivo;
  final bool invitado;
  final Expediente? expediente;
  final ValueChanged<Expediente>? abrir;
  final VoidCallback? volver;

  @override
  State<PanelExpedientes> createState() => _PanelExpedientesState();
}

class _PanelExpedientesState extends State<PanelExpedientes> {
  String busqueda = '';
  String? procesando;

  Future<void> _crear() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoExpediente(archivo: widget.archivo),
    );
    if (creado == true && mounted) _mensaje('Expediente guardado en Firebase.');
  }

  Future<void> _publicarExpediente(Expediente expediente, bool valor) async {
    if (!valor) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ocultar expediente'),
          content: const Text(
            'El invitado dejará de ver el expediente y sus documentos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ocultar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    setState(() => procesando = expediente.id);
    try {
      await widget.archivo.publicarExpediente(expediente, valor);
      if (mounted) {
        _mensaje(valor ? 'Expediente publicado.' : 'Expediente oculto.');
      }
    } catch (e) {
      if (mounted) _mensaje('No se pudo cambiar la visibilidad: $e');
    } finally {
      if (mounted) setState(() => procesando = null);
    }
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    if (widget.expediente != null) {
      return _DetalleExpediente(
        archivo: widget.archivo,
        invitado: widget.invitado,
        expediente: widget.expediente!,
        volver: widget.volver!,
      );
    }
    return StreamBuilder<List<Expediente>>(
      stream: widget.archivo.listarExpedientes(invitado: widget.invitado),
      builder: (context, estado) {
        final todos = estado.data ?? [];
        final visibles = todos.where((e) {
          final texto = '${e.codigo} ${e.descripcion} ${e.tipoOperacion}'
              .toLowerCase();
          return texto.contains(busqueda.toLowerCase().trim());
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  widget.invitado ? 'Expedientes publicados' : 'Expedientes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (!widget.invitado)
                  FilledButton.icon(
                    onPressed: _crear,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo expediente'),
                  ),
              ],
            ),
            if (widget.invitado)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Solo se muestran expedientes y documentos autorizados.',
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por código, descripción o tipo',
              ),
              onChanged: (valor) => setState(() => busqueda = valor),
            ),
            const SizedBox(height: 16),
            if (estado.hasError)
              _Aviso('No se pudieron cargar los expedientes: ${estado.error}')
            else if (!estado.hasData)
              const Center(child: CircularProgressIndicator())
            else if (visibles.isEmpty)
              _Aviso(
                busqueda.isEmpty
                    ? 'Todavía no hay expedientes disponibles.'
                    : 'No hay resultados para esa búsqueda.',
              )
            else
              ...visibles.map(
                (expediente) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(expediente.codigo),
                    subtitle: Text(
                      '${expediente.tipoOperacion} · ${expediente.descripcion}',
                    ),
                    trailing: widget.invitado
                        ? const Icon(Icons.chevron_right)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (procesando == expediente.id)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Switch.adaptive(
                                  value: expediente.visibleParaInvitados,
                                  onChanged: (valor) =>
                                      _publicarExpediente(expediente, valor),
                                ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                    onTap: () => widget.abrir?.call(expediente),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetalleExpediente extends StatefulWidget {
  const _DetalleExpediente({
    required this.archivo,
    required this.invitado,
    required this.expediente,
    required this.volver,
  });
  final ArchivoRepository archivo;
  final bool invitado;
  final Expediente expediente;
  final VoidCallback volver;

  @override
  State<_DetalleExpediente> createState() => _DetalleExpedienteState();
}

class _DetalleExpedienteState extends State<_DetalleExpediente> {
  String busqueda = '';
  String? procesando;

  Future<void> _subir() async {
    final subido = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoDocumento(
        archivo: widget.archivo,
        expedienteId: widget.expediente.id,
      ),
    );
    if (subido == true && mounted) _mensaje('Documento guardado en Firebase.');
  }

  Future<void> _publicar(Documento documento, bool valor) async {
    setState(() => procesando = documento.id);
    try {
      await widget.archivo.publicarDocumento(
        widget.expediente.id,
        documento,
        valor,
      );
      if (mounted) {
        _mensaje(valor ? 'Documento publicado.' : 'Documento oculto.');
      }
    } catch (e) {
      if (mounted) _mensaje('No se pudo cambiar la visibilidad: $e');
    } finally {
      if (mounted) setState(() => procesando = null);
    }
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Documento>>(
    stream: widget.archivo.listarDocumentos(
      widget.expediente.id,
      invitado: widget.invitado,
    ),
    builder: (context, estado) {
      final documentos = (estado.data ?? []).where((documento) {
        final texto = '${documento.nombreOriginal} ${documento.tipoDocumento}'
            .toLowerCase();
        return texto.contains(busqueda.toLowerCase().trim());
      }).toList();
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.volver,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Expedientes'),
            ),
          ),
          Text(
            widget.expediente.codigo,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            '${widget.expediente.tipoOperacion} · ${widget.expediente.descripcion}',
          ),
          const SizedBox(height: 12),
          if (!widget.invitado && !widget.expediente.visibleParaInvitados)
            const _Aviso(
              'Este expediente está privado. Publícalo antes de publicar documentos.',
            ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text('Documentos', style: Theme.of(context).textTheme.titleLarge),
              if (!widget.invitado)
                FilledButton.icon(
                  onPressed: _subir,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir documento'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar documento por nombre o tipo',
            ),
            onChanged: (valor) => setState(() => busqueda = valor),
          ),
          const SizedBox(height: 16),
          if (estado.hasError)
            _Aviso('No se pudieron cargar los documentos: ${estado.error}')
          else if (!estado.hasData)
            const Center(child: CircularProgressIndicator())
          else if (documentos.isEmpty)
            _Aviso(
              busqueda.isEmpty
                  ? 'Aún no hay documentos disponibles.'
                  : 'No hay documentos con ese criterio.',
            )
          else
            ...documentos.map(
              (documento) => Card(
                child: ListTile(
                  leading: Icon(
                    documento.tipoMime == 'application/pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(documento.nombreOriginal),
                  subtitle: Text(documento.tipoDocumento),
                  trailing: widget.invitado
                      ? const Icon(Icons.visibility_outlined)
                      : procesando == documento.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch.adaptive(
                          value: documento.visibleParaInvitados,
                          onChanged:
                              widget.expediente.visibleParaInvitados ||
                                  documento.visibleParaInvitados
                              ? (valor) => _publicar(documento, valor)
                              : null,
                        ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => _VistaDocumento(
                      archivo: widget.archivo,
                      documento: documento,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _DialogoExpediente extends StatefulWidget {
  const _DialogoExpediente({required this.archivo});
  final ArchivoRepository archivo;
  @override
  State<_DialogoExpediente> createState() => _DialogoExpedienteState();
}

class _DialogoExpedienteState extends State<_DialogoExpediente> {
  final formulario = GlobalKey<FormState>();
  final descripcion = TextEditingController();
  String tipo = 'importación';
  bool guardando = false;
  String? error;

  @override
  void dispose() {
    descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!formulario.currentState!.validate()) return;
    setState(() {
      guardando = true;
      error = null;
    });
    try {
      await widget.archivo.crearExpediente(
        tipoOperacion: tipo,
        descripcion: descripcion.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nuevo expediente'),
    content: SizedBox(
      width: 450,
      child: Form(
        key: formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: tipo,
              decoration: const InputDecoration(labelText: 'Tipo de operación'),
              items: const ['importación', 'exportación']
                  .map(
                    (opcion) =>
                        DropdownMenuItem(value: opcion, child: Text(opcion)),
                  )
                  .toList(),
              onChanged: guardando
                  ? null
                  : (valor) => setState(() => tipo = valor!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descripcion,
              maxLength: 180,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (valor) => valor == null || valor.trim().isEmpty
                  ? 'Escribe una descripción.'
                  : null,
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (guardando) const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: guardando ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: guardando ? null : _guardar,
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _DialogoDocumento extends StatefulWidget {
  const _DialogoDocumento({required this.archivo, required this.expedienteId});
  final ArchivoRepository archivo;
  final String expedienteId;
  @override
  State<_DialogoDocumento> createState() => _DialogoDocumentoState();
}

class _DialogoDocumentoState extends State<_DialogoDocumento> {
  static const tipos = [
    'Factura comercial',
    'Documento de transporte',
    'DUCA (cuando aplique)',
    'Declaración de valor',
    'Certificado de origen',
    'Permiso o autorización',
    'Otro',
  ];
  String tipo = tipos.first;
  PlatformFile? archivo;
  bool guardando = false;
  String? error;

  Future<void> _seleccionar() async {
    try {
      final elegido = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (mounted) {
        setState(() {
          archivo = elegido;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo seleccionar el archivo: $e');
      }
    }
  }

  Future<void> _guardar() async {
    final elegido = archivo;
    if (elegido == null) {
      setState(() => error = 'Selecciona un archivo.');
      return;
    }
    setState(() {
      guardando = true;
      error = null;
    });
    try {
      final tamano = elegido.lengthSync() ?? await elegido.length();
      if (tamano == null ||
          tamano <= 0 ||
          tamano > ArchivoValidador.tamanoMaximo) {
        throw const FormatException(
          'El archivo debe medir entre 1 byte y 10 MB.',
        );
      }
      final bytes = await elegido.readAsBytes();
      ArchivoValidador.validar(elegido.name, bytes);
      await widget.archivo.subirDocumento(
        expedienteId: widget.expedienteId,
        nombre: elegido.name,
        tipoDocumento: tipo,
        bytes: bytes,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo subir: $e');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Subir documento'),
    content: SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: tipo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo documental'),
            items: tipos
                .map(
                  (valor) => DropdownMenuItem(value: valor, child: Text(valor)),
                )
                .toList(),
            onChanged: guardando
                ? null
                : (valor) => setState(() => tipo = valor!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: guardando ? null : _seleccionar,
            icon: const Icon(Icons.attach_file),
            label: const Text('Seleccionar PDF, JPG o PNG'),
          ),
          if (archivo != null)
            Text(archivo!.name, overflow: TextOverflow.ellipsis),
          const Text('Tamaño máximo: 10 MB'),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (guardando) const LinearProgressIndicator(),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: guardando ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: guardando ? null : _guardar,
        child: const Text('Subir'),
      ),
    ],
  );
}

class _VistaDocumento extends StatelessWidget {
  const _VistaDocumento({required this.archivo, required this.documento});
  final ArchivoRepository archivo;
  final Documento documento;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: Text(documento.nombreOriginal),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: FutureBuilder(
        future: archivo.obtenerArchivo(documento),
        builder: (context, estado) {
          if (estado.hasError) {
            return _Aviso('No se pudo abrir el archivo: ${estado.error}');
          }
          if (!estado.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = estado.data!;
          return documento.tipoMime == 'application/pdf'
              ? _LectorPdf(bytes: bytes)
              : InteractiveViewer(child: Center(child: Image.memory(bytes)));
        },
      ),
    ),
  );
}

class _LectorPdf extends StatefulWidget {
  const _LectorPdf({required this.bytes});
  final Uint8List bytes;

  @override
  State<_LectorPdf> createState() => _LectorPdfState();
}

class _LectorPdfState extends State<_LectorPdf> {
  late final controlador = PdfControllerPinch(
    document: PdfDocument.openData(widget.bytes),
  );

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PdfViewPinch(controller: controlador);
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Text(texto)),
  );
}
