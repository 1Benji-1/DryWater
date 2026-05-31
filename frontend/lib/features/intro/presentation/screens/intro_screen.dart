import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

/// Permite el desplazamiento con mouse en plataformas Web/Desktop
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  double _currentPageOffset = 0.0;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (_pageController.hasClients) {
      final page = _pageController.page ?? 0.0;
      setState(() {
        _currentPageOffset = page;
      });

      // Si desliza hacia la derecha pasado el límite de la pestaña 3 (requiere deslizamiento mayor, > 2.8)
      if (page > 2.8 && !_navigating) {
        _navigating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(RouteNames.login);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (_navigating) return;
    _navigating = true;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Fondo oscuro para centrar la app en web/escritorio
      body: Center(
        child: Container(
          // Restringimos el ancho al de un celular móvil para proporción en Chrome
          constraints: const BoxConstraints(maxWidth: 450),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFC3E7C9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Fondo de Montañas con Paralaje continuo matemático (Curvas Grandes y Limpias)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: HillsParallaxPainter(
                        pageOffset: _currentPageOffset,
                      ),
                    );
                  },
                ),
              ),

              // 2. Contenido del PageView (Textos de las pestañas con soporte para mouse drag)
              PageView(
                controller: _pageController,
                scrollBehavior: AppScrollBehavior(), // Habilitar arrastre con mouse
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPage(
                    title: "MÁS VALE PREVENIR\nQUE CURAR",
                  ),
                  _buildPage(
                    title: "PLANIFICAR ES\nCONSTRUIR SEGURIDAD",
                  ),
                  _buildPage(
                    title: "PREVER ES SEMBRAR\nCON VENTAJA",
                  ),
                  // Página vacía para capturar el scroll de transición final
                  const SizedBox.shrink(),
                ],
              ),

              // 3. Indicadores de páginas (Dots) y Botón de Inicio
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fila de dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          double difference = (_currentPageOffset - index).abs();
                          double activeFactor = (1.0 - difference).clamp(0.0, 1.0);
                          double size = 8.0 + (4.0 * activeFactor);
                          double opacity = 0.4 + (0.6 * activeFactor);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(opacity),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Botón "Comenzar" que aparece con fade-in en la pestaña 3
                      AnimatedOpacity(
                        opacity: (_currentPageOffset - 1.0).clamp(0.0, 1.0),
                        duration: const Duration(milliseconds: 100),
                        child: IgnorePointer(
                          ignoring: _currentPageOffset < 1.5,
                          child: Container(
                            width: 200,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF246D34),
                                  Color(0xFF10471D),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _goToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                "Comenzar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({required String title}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              fontFamily: 'Georgia',
              fontFamilyFallback: const ['Didot', 'Times New Roman', 'serif'],
              letterSpacing: 3.0,
              height: 1.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HillsParallaxPainter extends CustomPainter {
  final double pageOffset;

  HillsParallaxPainter({required this.pageOffset});

  // Altura matemática de las montañas: grandes, continuas y con pendientes pronunciadas
  double _getHillHeight(double x, double w, double h, int layerIndex) {
    switch (layerIndex) {
      case 1:
        // Montaña más lejana: inicia alta y baja suavemente
        return h * 0.22 + (h * 0.05) * math.sin(x * 2 * math.pi / w * 0.35 + 1.5);
      case 2:
        // Segunda capa: pendiente opuesta, sube de derecha a izquierda
        return h * 0.34 + (h * 0.06) * math.cos(x * 2 * math.pi / w * 0.4 + 2.8);
      case 3:
        // Tercera capa: colina suave central
        return h * 0.46 + (h * 0.065) * math.sin(x * 2 * math.pi / w * 0.35 + 4.2);
      case 4:
        // Cuarta capa: pendiente pronunciada hacia la derecha
        return h * 0.58 + (h * 0.07) * math.cos(x * 2 * math.pi / w * 0.45 + 0.8);
      case 5:
        // Primer plano: montaña de base que cubre el área inferior
        return h * 0.70 + (h * 0.05) * math.sin(x * 2 * math.pi / w * 0.5 + 5.0);
      default:
        return h * 0.7;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0. Cielo verde claro plano (Idéntico a la imagen)
    final skyPaint = Paint()..color = const Color(0xFFC3E7C9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 1. Luna (círculo limpio verde claro/blanquecino en la pestaña 3)
    double moonX = (0.98 * w) - (pageOffset * w * 0.08);
    double moonY = h * 0.14;
    final moonPaint = Paint()..color = const Color(0xFFE4F8EB);
    canvas.drawCircle(Offset(moonX, moonY), 28, moonPaint);

    // 2. Capa 1: Verde suave (#A1D4AB)
    _drawHillLayer(canvas, w, h, const Color(0xFFA1D4AB), 0.15, 1);

    // 3. Capa 2: Verde medio (#75B884)
    _drawHillLayer(canvas, w, h, const Color(0xFF75B884), 0.30, 2);

    // 4. Capa 3: Verde bosque (#449557)
    _drawHillLayer(canvas, w, h, const Color(0xFF449557), 0.45, 3);

    // 5. Capa 4: Verde oscuro (#246D34)
    _drawHillLayer(canvas, w, h, const Color(0xFF246D34), 0.65, 4);

    // 6. Capa 5: Verde muy oscuro (#10471D)
    _drawHillLayer(canvas, w, h, const Color(0xFF10471D), 0.85, 5);
  }

  void _drawHillLayer(
    Canvas canvas,
    double width,
    double height,
    Color color,
    double parallaxFactor,
    int layerIndex,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    double translation = -pageOffset * width * parallaxFactor;
    
    path.moveTo(0, height);
    for (double x = 0; x <= width; x += 4) {
      double layerX = x - translation;
      double y = _getHillHeight(layerX, width, height, layerIndex);
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HillsParallaxPainter oldDelegate) {
    return oldDelegate.pageOffset != pageOffset;
  }
}
