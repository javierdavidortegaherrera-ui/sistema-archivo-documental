# Demostraciones visuales

`pc-demo.mp4` y `android-demo.mp4` reúnen capturas de widgets Flutter con dos expedientes ficticios. Son secuencias de imágenes de prueba: no representan sesiones grabadas en un navegador o teléfono físico ni verifican el acceso a Firebase.

`android-telefono.mp4` se grabó con `adb shell screenrecord` en un teléfono Android conectado por USB. Muestra el modo invitado, el expediente ficticio `EXP-2026-0002` y la apertura de `certificado_origen_demo_cafe.pdf` desde el proyecto Firebase de demostración. Se recortaron las barras de estado y navegación del teléfono; no se muestran credenciales. El video es una muestra de ese recorrido, no una prueba automatizada de todos los permisos.

Las capturas de widgets se generan sin contraseñas, cuentas ni datos del proyecto remoto. El generador está en `tool/generar_capturas_test.dart` y prueba la portada, el panel administrativo y los listados de expedientes y documentos en tamaños de PC y Android.

## Reproducir

Con Flutter y las fuentes Material del SDK instalados:

```bash
flutter test tool/generar_capturas_test.dart --reporter expanded
```

Si Flutter está en otra ubicación, define `FLUTTER_ROOT` con la ruta del SDK antes de ejecutar el generador. Para reconstruir los MP4, instala FFmpeg y ejecuta desde la raíz del repositorio:

```bash
ffmpeg -y -f concat -safe 0 -i docs/demo/pc-secuencia.txt -vf "fps=15,format=yuv420p" -c:v libx264 -crf 24 -movflags +faststart docs/demo/pc-demo.mp4
ffmpeg -y -f concat -safe 0 -i docs/demo/android-secuencia.txt -vf "fps=15,format=yuv420p" -c:v libx264 -crf 24 -movflags +faststart docs/demo/android-demo.mp4
```

Las imágenes de los PDF se obtuvieron de los archivos ficticios de `output/pdf/`. No tienen validez comercial, legal ni aduanera.
