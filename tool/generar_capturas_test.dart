import 'dart:io';
import 'dart:ui' as ui;

import 'package:archivo_documental_aduanero/models/documento.dart';
import 'package:archivo_documental_aduanero/models/expediente.dart';
import 'package:archivo_documental_aduanero/repositories/archivo_repository.dart';
import 'package:archivo_documental_aduanero/screens/acceso/pantalla_acceso.dart';
import 'package:archivo_documental_aduanero/screens/inicio/pantalla_inicio.dart';
import 'package:archivo_documental_aduanero/services/acceso_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _captura = Key('captura-demo');
const _expedienteRepuestos = Expediente(
  id: 'demo-importacion-repuestos',
  codigo: 'EXP-2026-0001',
  tipoOperacion: 'importación',
  descripcion: 'Ingreso de repuestos automotrices para demostración',
  estado: 'abierto',
  visibleParaInvitados: true,
);
const _expedienteCafe = Expediente(
  id: 'demo-exportacion-cafe',
  codigo: 'EXP-2026-0002',
  tipoOperacion: 'exportación',
  descripcion: 'Envío de café tostado de muestra',
  estado: 'abierto',
  visibleParaInvitados: true,
);

class _ArchivoDemo extends Fake implements ArchivoRepository {
  @override
  Stream<List<Expediente>> listarExpedientes({required bool invitado}) =>
      Stream.value([_expedienteRepuestos, _expedienteCafe]);

  @override
  Stream<List<Documento>> listarDocumentos(
    String expedienteId, {
    required bool invitado,
  }) => Stream.value([
    if (expedienteId == _expedienteCafe.id)
      const Documento(
        id: 'demo-certificado-cafe',
        nombreOriginal: 'certificado_origen_demo_cafe.pdf',
        tipoDocumento: 'Certificado de origen',
        storagePath: '',
        tipoMime: 'application/pdf',
        visibleParaInvitados: true,
      )
    else
      const Documento(
        id: 'demo-factura-repuestos',
        nombreOriginal: 'factura_comercial_demo_repuestos.pdf',
        tipoDocumento: 'Factura comercial',
        storagePath: '',
        tipoMime: 'application/pdf',
        visibleParaInvitados: true,
      ),
  ]);
}

class _AccesoDemo extends Fake implements AccesoService {}

void _tamano(WidgetTester tester, Size tamano, double escala) {
  tester.view.devicePixelRatio = escala;
  tester.view.physicalSize = Size(
    tamano.width * escala,
    tamano.height * escala,
  );
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D3B99)),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  ),
  home: RepaintBoundary(key: _captura, child: child),
);

Future<void> _guardar(WidgetTester tester, String nombre, double escala) async {
  await tester.pump(const Duration(milliseconds: 100));
  final borde = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captura),
  );
  await tester.runAsync(() async {
    final imagen = await borde.toImage(pixelRatio: escala);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    final directorio = Directory('docs/capturas')..createSync(recursive: true);
    File('${directorio.path}/$nombre')
        .writeAsBytesSync(Uint8List.view(datos!.buffer));
  });
}

void main() {
  setUpAll(() async {
    final raizFlutter =
        Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter/src/flutter';
    final carpeta = '$raizFlutter/bin/cache/artifacts/material_fonts';
    for (final (familia, archivo) in [
      ('Roboto', 'roboto-regular.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      final bytes = File('$carpeta/$archivo').readAsBytesSync();
      final cargador = FontLoader(familia)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await cargador.load();
    }
  });

  testWidgets('capturas web con datos ficticios', (tester) async {
    _tamano(tester, const Size(1280, 720), 1);
    final archivo = _ArchivoDemo();
    final acceso = _AccesoDemo();

    await tester.pumpWidget(_app(PantallaAcceso(acceso: acceso)));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/logo_aduanero.png'),
        tester.element(find.byType(PantallaAcceso)),
      ),
    );
    await tester.pump();
    expect(find.text('Continuar como invitado'), findsOneWidget);
    await _guardar(tester, 'web-acceso.png', 1);

    await tester.pumpWidget(
      _app(PantallaInicio(archivo: archivo, acceso: acceso, invitado: false)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Panel de administrador'), findsOneWidget);
    await _guardar(tester, 'web-administrador.png', 1);

    await tester.tap(find.text('Expedientes').first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('EXP-2026-0001'), findsOneWidget);
    await _guardar(tester, 'web-expedientes.png', 1);
  });

  testWidgets('capturas Android con datos ficticios', (tester) async {
    _tamano(tester, const Size(390, 844), 2);
    final archivo = _ArchivoDemo();
    final acceso = _AccesoDemo();

    await tester.pumpWidget(_app(PantallaAcceso(acceso: acceso)));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/logo_aduanero.png'),
        tester.element(find.byType(PantallaAcceso)),
      ),
    );
    await tester.pump();
    expect(find.text('Continuar como invitado'), findsOneWidget);
    await _guardar(tester, 'android-acceso.png', 2);

    await tester.pumpWidget(
      _app(PantallaInicio(archivo: archivo, acceso: acceso, invitado: true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('EXP-2026-0002'), findsOneWidget);
    await _guardar(tester, 'android-expedientes.png', 2);

    await tester.tap(find.text('EXP-2026-0002'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('certificado_origen_demo_cafe.pdf'), findsOneWidget);
    await _guardar(tester, 'android-documentos.png', 2);
  });
}
