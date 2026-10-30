import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConfiguracionFirebase {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static bool get completa =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty &&
      storageBucket.isNotEmpty &&
      (kIsWeb ? webAppId.isNotEmpty : androidAppId.isNotEmpty);

  static FirebaseOptions get opciones => FirebaseOptions(
    apiKey: apiKey,
    appId: kIsWeb ? webAppId : androidAppId,
    messagingSenderId: senderId,
    projectId: projectId,
    storageBucket: storageBucket,
    authDomain: kIsWeb ? authDomain : null,
  );
}

class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key, this.error});
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Falta configurar Firebase',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'Crea firebase.local.json con los identificadores de tu proyecto '
                'y ejecuta Flutter con --dart-define-from-file=firebase.local.json. '
                'Consulta el README para los pasos completos.',
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                SelectableText(error!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
