import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.destination});
  final Widget destination;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _logoScale = CurvedAnimation(parent: _controller, curve: const Interval(0, .7, curve: Curves.easeOutBack));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(.25, 1, curve: Curves.easeIn));
    _openDestination();
  }

  Future<void> _openDestination() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => widget.destination,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007A78);
    return Scaffold(body: DecoratedBox(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Color(0xFFE3F3F1)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Stack(children: [
        Positioned(top: -100, right: -75, child: FadeTransition(opacity: _fadeIn, child: Container(width: 250, height: 250, decoration: const BoxDecoration(color: Color(0x1A007A78), shape: BoxShape.circle)))),
        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(scale: _logoScale, child: Image.asset('assets/images/denteagendalogo.png', width: 285, semanticLabel: 'Logo DenteAgenda')),
          const SizedBox(height: 30),
          FadeTransition(opacity: _fadeIn, child: const Column(children: [
            Text('Sua saúde bucal organizada', textAlign: TextAlign.center, style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 18),
            SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: primary)),
          ])),
        ]))),
      ]),
    ));
  }
}

void openWithSplash(BuildContext context, Widget destination) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SplashScreen(destination: destination)));
}
