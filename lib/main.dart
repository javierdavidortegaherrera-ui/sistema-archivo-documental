import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/aplicacion.dart';
import 'core/firebase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!ConfiguracionFirebase.completa) {
    runApp(const MaterialApp(home: PantallaConfiguracion()));
    return;
  }
  try {
    await Firebase.initializeApp(options: ConfiguracionFirebase.opciones);
    runApp(const Aplicacion());
  } catch (error) {
    runApp(MaterialApp(home: PantallaConfiguracion(error: error.toString())));
  }
}
