import 'dart:async';

import 'package:archivo_documental_aduanero/models/documento.dart';
import 'package:archivo_documental_aduanero/models/expediente.dart';
import 'package:archivo_documental_aduanero/repositories/archivo_repository.dart';
import 'package:archivo_documental_aduanero/screens/expedientes/panel_expedientes.dart';
import 'package:archivo_documental_aduanero/widgets/carga_esqueleto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ArchivoPendiente extends Fake implements ArchivoRepository {
  final expedientes = StreamController<List<Expediente>>.broadcast();
  final documentos = StreamController<List<Documento>>.broadcast();

  @override
  Stream<List<Expediente>> listarExpedientes({required bool invitado}) =>
      expedientes.stream;

  @override
  Stream<List<Documento>> listarDocumentos(
    String expedienteId, {
    required bool invitado,
  }) => documentos.stream;

  Future<void> cerrar() async {
    await expedientes.close();
    await documentos.close();
  }
}

void main() {
  testWidgets('el listado muestra esqueleto hasta recibir expedientes', (
    tester,
  ) async {
    final archivo = _ArchivoPendiente();
    addTearDown(archivo.cerrar);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelExpedientes(
            archivo: archivo,
            invitado: true,
            abrir: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(ListaEsqueleto), findsOneWidget);
    expect(find.text('Todavía no hay expedientes disponibles.'), findsNothing);
    expect(tester.takeException(), isNull);

    archivo.expedientes.add(const [
      Expediente(
        id: 'demo',
        codigo: 'EXP-2026-0001',
        tipoOperacion: 'importación',
        descripcion: 'Repuestos de muestra',
        estado: 'abierto',
        visibleParaInvitados: true,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('EXP-2026-0001'), findsOneWidget);
    expect(find.byType(ListaEsqueleto), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el esqueleto de documentos da paso al estado vacío', (
    tester,
  ) async {
    final archivo = _ArchivoPendiente();
    addTearDown(archivo.cerrar);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelExpedientes(
            archivo: archivo,
            invitado: true,
            expediente: const Expediente(
              id: 'demo',
              codigo: 'EXP-2026-0002',
              tipoOperacion: 'exportación',
              descripcion: 'Café de muestra',
              estado: 'abierto',
              visibleParaInvitados: true,
            ),
            volver: () {},
          ),
        ),
      ),
    );

    expect(find.byType(ListaEsqueleto), findsOneWidget);
    expect(find.text('Aún no hay documentos disponibles.'), findsNothing);

    archivo.documentos.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(ListaEsqueleto), findsNothing);
    expect(find.text('Aún no hay documentos disponibles.'), findsOneWidget);
  });
}
