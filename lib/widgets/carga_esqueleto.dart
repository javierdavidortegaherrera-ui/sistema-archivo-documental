import 'package:flutter/material.dart';

/// Anima los marcadores de posición con una sola línea de brillo.
class CargaEsqueleto extends StatefulWidget {
  const CargaEsqueleto({super.key, required this.child});

  final Widget child;

  @override
  State<CargaEsqueleto> createState() => _CargaEsqueletoState();
}

class _CargaEsqueletoState extends State<CargaEsqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducirMovimiento =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducirMovimiento) {
      controlador.stop();
    } else if (!controlador.isAnimating) {
      controlador.repeat();
    }
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando contenido',
    liveRegion: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controlador,
        child: widget.child,
        builder: (context, child) =>
            _BrilloEsqueleto(progreso: controlador.value, child: child!),
      ),
    ),
  );
}

class _BrilloEsqueleto extends InheritedWidget {
  const _BrilloEsqueleto({required this.progreso, required super.child});

  final double progreso;

  @override
  bool updateShouldNotify(_BrilloEsqueleto anterior) =>
      progreso != anterior.progreso;
}

class BloqueEsqueleto extends StatelessWidget {
  const BloqueEsqueleto({
    super.key,
    this.ancho = double.infinity,
    required this.alto,
    this.radio = 8,
  });

  final double ancho;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final progreso =
        context
            .dependOnInheritedWidgetOfExactType<_BrilloEsqueleto>()
            ?.progreso ??
        0.5;
    return SizedBox(
      width: ancho,
      height: alto,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radio),
          gradient: LinearGradient(
            begin: Alignment(-2 + 3 * progreso, 0),
            end: Alignment(-1 + 3 * progreso, 0),
            colors: [
              esquema.surfaceContainerHighest,
              esquema.surfaceContainerLow,
              esquema.surfaceContainerHighest,
            ],
          ),
        ),
      ),
    );
  }
}

class ListaEsqueleto extends StatelessWidget {
  const ListaEsqueleto({super.key, this.cantidad = 3});

  final int cantidad;

  @override
  Widget build(BuildContext context) => CargaEsqueleto(
    child: Column(
      children: List.generate(
        cantidad,
        (indice) => Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                const BloqueEsqueleto(ancho: 28, alto: 28, radio: 6),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BloqueEsqueleto(alto: 18),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: indice.isEven ? 0.72 : 0.55,
                        alignment: Alignment.centerLeft,
                        child: const BloqueEsqueleto(alto: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const BloqueEsqueleto(ancho: 18, alto: 18, radio: 4),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DocumentoEsqueleto extends StatelessWidget {
  const DocumentoEsqueleto({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: CargaEsqueleto(
          child: Card(
            child: AspectRatio(
              aspectRatio: 0.71,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BloqueEsqueleto(alto: 36, radio: 4),
                    const SizedBox(height: 24),
                    const BloqueEsqueleto(alto: 22),
                    const SizedBox(height: 18),
                    for (var indice = 0; indice < 5; indice++) ...[
                      FractionallySizedBox(
                        widthFactor: indice.isEven ? 0.9 : 0.7,
                        child: const BloqueEsqueleto(alto: 14),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AccesoEsqueleto extends StatelessWidget {
  const AccesoEsqueleto({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: CargaEsqueleto(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BloqueEsqueleto(ancho: 140, alto: 140, radio: 24),
                  const SizedBox(height: 28),
                  const BloqueEsqueleto(alto: 32),
                  const SizedBox(height: 12),
                  const BloqueEsqueleto(alto: 18),
                  const SizedBox(height: 64),
                  const BloqueEsqueleto(alto: 54, radio: 28),
                  const SizedBox(height: 16),
                  const BloqueEsqueleto(alto: 54, radio: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class InicioEsqueleto extends StatelessWidget {
  const InicioEsqueleto({super.key, required this.invitado});

  final bool invitado;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Row(
        children: [
          const BloqueEsqueleto(ancho: 42, alto: 42, radio: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: BloqueEsqueleto(ancho: invitado ? 180 : 230, alto: 22),
            ),
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CargaEsqueleto(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BloqueEsqueleto(ancho: 260, alto: 32),
              const SizedBox(height: 12),
              const BloqueEsqueleto(ancho: 230, alto: 16),
              const SizedBox(height: 24),
              if (invitado) const BloqueEsqueleto(alto: 54),
              if (!invitado)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    3,
                    (_) => const Card(
                      child: SizedBox(
                        width: 190,
                        height: 130,
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BloqueEsqueleto(ancho: 24, alto: 24),
                              SizedBox(height: 14),
                              BloqueEsqueleto(ancho: 72, alto: 25),
                              SizedBox(height: 8),
                              BloqueEsqueleto(ancho: 110, alto: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (invitado) ...[const SizedBox(height: 16), const ListaEsqueleto()],
      ],
    ),
  );
}
