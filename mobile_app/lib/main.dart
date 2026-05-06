import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DermavisionApp());
}

class DermavisionApp extends StatelessWidget {
  const DermavisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dermavision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          final args = settings.arguments;
          if (args is ResultScreenArgs) {
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => ResultScreen(args: args),
              transitionsBuilder: (_, a, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                ),
                child: FadeTransition(opacity: a, child: child),
              ),
              transitionDuration: const Duration(milliseconds: 450),
            );
          }
        }

        switch (settings.name) {
          case '/':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SplashScreen(),
              transitionDuration: Duration.zero,
            );
          case '/home':
          default:
            return PageRouteBuilder(
              pageBuilder: (_, a, ___) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            );
        }
      },
    );
  }
}
