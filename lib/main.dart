import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/home_page.dart';
import 'screens/splash_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions  (
        apiKey: "AIzaSyBWo9zL1_i5mi2itCYsewKIWYx31X2mvg0",
        authDomain: "dentagenda1-1569f.firebaseapp.com",
        projectId: "dentagenda1-1569f",
        storageBucket: "dentagenda1-1569f.firebasestorage.app",
        messagingSenderId: "690070880478",
        appId: "1:690070880478:web:3a37757af50de35d96424f"
      )
    );
    
  } catch (_) {
    // Firebase can be configured later with FlutterFire for each platform.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DenteAgenda',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007A78),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const SplashScreen(destination: HomePage()),
    );
  }
}

class LegacySplashScreen extends StatefulWidget {
  const LegacySplashScreen({super.key});

  @override
  State<LegacySplashScreen> createState() => _LegacySplashScreenState();
}

class _LegacySplashScreenState extends State<LegacySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .7, curve: Curves.easeOutBack),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.25, 1, curve: Curves.easeIn),
    );
    _openHome();
  }

  Future<void> _openHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007A78);
    const lightTeal = Color(0xFFE3F3F1);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, lightTeal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -75,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0x1A007A78),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/denteagendalogo.png',
                        width: 285,
                        semanticLabel: 'Logo DenteAgenda',
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const Column(
                        children: [
                          Text(
                            'Sua saúde bucal organizada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 18),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


