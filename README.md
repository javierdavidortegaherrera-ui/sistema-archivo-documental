# Sistema de Archivo y Control Documental Aduanero

Prototipo académico y de portafolio independiente, no afiliado a ninguna empresa ni institución aduanera y sin integración con servicios gubernamentales. Usa únicamente expedientes y documentos ficticios de demostración.

## Objetivo

Organizar expedientes de importación y exportación, guardar PDF e imágenes en la nube y permitir que un invitado vea solo lo publicado por un administrador. Resuelve la dispersión de archivos y la falta de una vista clara sobre qué documentos se pueden consultar.

## Alcance implementado

- Una aplicación Flutter para Android y web, con Material 3 y el logotipo original en `assets/images/logo_aduanero.png`.
- Acceso Email/Password para administradores preautorizados y acceso anónimo sin registro para invitados.
- Alta y listado de expedientes con código `EXP-AÑO-NNNN`, generado con contador transaccional en Firestore.
- Carga de PDF, JPG y PNG de hasta 10 MB, con comprobación de extensión y firma básica del contenido.
- Metadatos en Firestore, archivo en Cloud Storage y vista previa en la aplicación.
- La vista PDF web usa PDF.js 4.6.82 incluido localmente en `web/pdfjs` bajo su licencia Apache 2.0; la visualización no carga código desde una CDN.
- Publicación u ocultación explícita de expedientes y documentos. Ambos son privados por defecto.
- Búsqueda simple por campos de los registros ya autorizados en la pantalla actual; no es búsqueda de texto completo.
- Registro técnico de accesos anónimos y panel de las 50 visitas recientes para administradores.
- Reglas de Firestore y Storage que reservan las escrituras de negocio a custom claims `admin` y solo permiten leer archivos de una versión publicada bajo un expediente publicado.

El archivo se sube primero a Storage y después se confirman sus metadatos en un lote de Firestore. Si falla Firestore, la aplicación intenta borrar el archivo. Una interrupción entre ambos servicios aún puede dejar un archivo huérfano privado, que deberá limpiar un administrador.

## Estructura

```text
lib/
  app/             aplicación, tema y control de sesión
  core/            configuración y validación de archivos
  models/          expedientes y documentos
  repositories/    operaciones Firestore y Storage
  services/        autenticación y registro de visitas
  screens/         acceso, inicio, expedientes y documentos
assets/images/     logotipo original
firestore.rules     permisos de datos
storage.rules       permisos de archivos
```

Los datos se guardan en Firebase, no en carpetas del dispositivo. Una reinstalación o borrado de datos locales no borra expedientes, documentos ni registros remotos. El `installationId` es aleatorio y local: si se borran los datos o se usa navegación privada, se puede crear una identidad técnica nueva. No se usan IMEI, MAC ni huellas del navegador. El registro de invitado escrito desde el cliente es un registro técnico de demostración, no una auditoría infalsificable.

## Preparar Firebase

1. Crea un proyecto Firebase propio con datos ficticios. Registra una app Android con ID `hn.portafolio.archivodocumentaladuanero` y una app Web. La configuración pública de las apps no es una credencial de servidor.
2. En **Authentication > Sign-in method**, habilita **Email/Password** y **Anonymous**. En **Authentication > Settings > Authorized domains**, añade `localhost` para pruebas web locales y el dominio donde publicarás la web, si corresponde. Los proyectos nuevos pueden no incluir `localhost` por defecto.
3. Crea Firestore en modo de reglas cerradas y un bucket de Cloud Storage. **Cloud Storage for Firebase requiere el plan Blaze**; revisa sus cuotas y configura un presupuesto antes de habilitarlo. El código no agrega Cloud Functions ni otros servicios de backend.
4. Copia `firebase.local.example.json` a `firebase.local.json` y completa los valores de las configuraciones de tus apps: la API key de Android (`current_key` en `google-services.json`), la API key web (`apiKey` del objeto de configuración), project ID, sender ID, bucket, app ID Android, app ID Web y auth domain. El archivo local está excluido de Git. No pongas contraseñas ni claves de servicio allí.
5. Instala Firebase CLI e inicia sesión en tu proyecto. Despliega **ambas** reglas desde esta carpeta con `firebase deploy --only firestore:rules,storage`. Al usar consultas de Firestore desde Storage Rules, Firebase puede solicitar habilitar el permiso de conexión entre ambos productos. Revisa la solicitud en la consola y confírmala para tu proyecto.
6. Para la vista previa web, configura CORS del bucket porque `getData()` descarga los bytes directamente. El ejemplo `storage.cors.example.json` permite solo solicitudes GET desde cualquier origen; antes de publicar una web, limita `origin` a sus dominios. Ejecuta `gsutil cors set storage.cors.example.json gs://<TU_BUCKET>` con Google Cloud CLI. CORS no concede acceso: las reglas de Storage siguen autorizando cada lectura. Consulta la [guía oficial de descarga web](https://firebase.google.com/docs/storage/web/download-files#cors_configuration).
7. Crea una cuenta Email/Password de demostración desde la consola Firebase, nunca desde un formulario público. Asigna el custom claim administrativo desde un entorno de confianza. El script incluido usa Application Default Credentials y requiere `pnpm install`, `GOOGLE_APPLICATION_CREDENTIALS` apuntando a una credencial **fuera del repositorio**, `GOOGLE_CLOUD_PROJECT` y `pnpm asignar-admin <UID>`. El operador debe verificar que el UID corresponde a la cuenta Email/Password deseada. Después, cierra e inicia sesión para renovar el token.

Las reglas se bloquean por defecto en rutas no declaradas. No publiques un bucket con reglas abiertas. Nunca subas la credencial administrativa, documentos reales o contraseñas a GitHub. El proyecto incluye `.gitignore` para los archivos de configuración local y credenciales con los nombres indicados.

## Ejecutar

Requiere Flutter compatible con Dart 3.13 y Android SDK para compilar Android.

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=firebase.local.json
flutter run -d android --dart-define-from-file=firebase.local.json
```

En Android, usa un emulador con Google Play o un dispositivo compatible. Si falta la configuración, la aplicación muestra una pantalla con los pasos a seguir. El logotipo ya está copiado y declarado en `pubspec.yaml`; los iconos Android y web se generaron a partir del mismo emblema con margen blanco, sin recortar avión, barco ni camión.

## Comprobar el flujo

1. Inicia sesión como administrador y crea un expediente ficticio.
2. Ábrelo, sube un PDF de prueba y comprueba la vista previa. Revisa en Firebase Console el documento de Firestore y el archivo de Storage.
3. Publica el expediente y luego el documento.
4. En otra sesión o navegador, entra como invitado. Comprueba que el expediente y el PDF aparecen y pueden visualizarse.
5. Oculta el documento y comprueba que desaparece y que su ruta de Storage deja de ser legible por el invitado. Repite con un documento privado desde el inicio.
6. Intenta escribir directamente en Firestore con un token anónimo: las reglas deben denegar escrituras de expedientes y documentos. El invitado solo puede crear o actualizar su propio `registros_invitados/{uid}` con los campos permitidos.
7. Comprueba desde otra instalación de administrador que el mismo expediente sigue visible. Borrar datos locales no debe borrar información remota.

Estas comprobaciones de Firebase requieren un proyecto configurado. Para probar permisos sin tocar producción, usa Firebase Local Emulator Suite con `firestore.rules` y `storage.rules` de este repositorio.

## Análisis y pruebas locales

```bash
flutter analyze
flutter test
flutter build web --dart-define-from-file=firebase.local.json
flutter build apk --debug --dart-define-from-file=firebase.local.json
```

La prueba incluida comprueba aceptación y rechazo de firmas de archivos. Las pruebas de reglas, el flujo remoto, la persistencia después de reinstalación y las capturas reales requieren Firebase o emuladores configurados.

## Capturas

Pendientes de capturar con una instancia Firebase de demostración configurada. No se incluyen pantallas con información real ni capturas simuladas como evidencia de ejecución.

## Limitaciones y siguientes fases

Este MVP no incluye edición/archivo de expedientes, checklist, reemplazo y consulta de versiones, historial de actividad ni filtros avanzados. El modelo guarda una primera versión para ampliar el flujo posteriormente. No valida autenticidad de documentos, requisitos legales, tributos ni estados oficiales. La vista previa no impide copiar o capturar el contenido. Los identificadores técnicos de invitados pueden cambiar al reinstalar la app o limpiar el navegador.

No hay sincronización automática con GitHub ni despliegue público incluido. Antes de publicar una demo, verifica las reglas en emuladores y con cuentas de prueba, sube solo datos ficticios y revisa costos de Firebase.
