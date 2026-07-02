import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final List<Animation<Offset>> _slides;
  late final List<Animation<double>> _fades;
  late final Animation<double> _line;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  static const _personCount = 5;

  static const _personColors = [
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  static const _personSizes = [54.0, 48.0, 58.0, 50.0, 56.0];

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoOpacity = _at(0.00, 0.15, Tween(begin: 0.0, end: 1.0));
    _logoScale = _at(
      0.00,
      0.30,
      Tween(begin: 0.3, end: 1.0),
      curve: Curves.elasticOut,
    );

    _slides = List.generate(_personCount, (i) {
      final s = 0.20 + i * 0.09;
      return _at(
        s,
        (s + 0.22).clamp(0.0, 1.0),
        Tween(begin: const Offset(3.0, 0.0), end: Offset.zero),
        curve: Curves.easeOutBack,
      );
    });

    _fades = List.generate(_personCount, (i) {
      final s = 0.20 + i * 0.09;
      return _at(s, (s + 0.10).clamp(0.0, 1.0), Tween(begin: 0.0, end: 1.0));
    });

    _line = _at(0.62, 0.80, Tween(begin: 0.0, end: 1.0));

    _titleOpacity = _at(0.74, 0.90, Tween(begin: 0.0, end: 1.0));
    _titleSlide = _at(
      0.74,
      0.90,
      Tween(begin: const Offset(0.0, 0.3), end: Offset.zero),
      curve: Curves.easeOut,
    );

    _ctrl.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 700), _navigate);
    });
  }

  Animation<T> _at<T>(
    double begin,
    double end,
    Tween<T> tween, {
    Curve curve = Curves.linear,
  }) =>
      tween.animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(begin, end, curve: curve),
        ),
      );

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) => widget.next,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder:
            (context, anim, secondary, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _person(int i) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          '#${i + 1}',
          style: TextStyle(
            color: _personColors[i],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Icon(Icons.person_rounded, size: _personSizes[i], color: _personColors[i]),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF311B92), Color(0xFF7B1FA2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo com fade + scale
              AnimatedBuilder(
                animation: _ctrl,
                builder:
                    (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    ),
                child: Image.asset(
                  'assets/logo_mobile_fila_facil.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 52),

              // Fila de pessoas com entrada escalonada da direita
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  _personCount,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SlideTransition(
                      position: _slides[i],
                      child: FadeTransition(
                        opacity: _fades[i],
                        child: _person(i),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Linha do chão que se expande da esquerda para direita
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: _line,
                  builder:
                      (context, child) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _line.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                ),
              ),

              const SizedBox(height: 44),

              // Nome e tagline com fade + slide para cima
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleOpacity,
                  child: const Column(
                    children: [
                      Text(
                        'Fila Fácil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Economize seu tempo na fila',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
