import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/empresa_screen.dart';
import 'screens/paciente_screen.dart';
import 'screens/visita_en_curso_screen.dart';
import 'screens/finalizar_visita_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 Configurar Crashlytics para capturar errores uncaught
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(const AprossApp());
}

class AprossApp extends StatelessWidget {
  const AprossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APROSS ID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A99D)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );

          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/empresa':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => EmpresaScreen(
                nombreEmpresa: args['nombreEmpresa'] ?? '',
                cuitEmpresa: args['cuitEmpresa'] ?? '',
              ),
            );

          case '/paciente':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => PacienteScreen(
                nombrePaciente: args['nombrePaciente'] ?? '',
                numeroAfiliacion: args['numeroAfiliacion'] ?? '',
                cuitEmpresa: args['cuitEmpresa'] ?? '',
                nombreEmpresa: args['nombreEmpresa'] ?? '',
              ),
            );

          case '/visita':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => VisitaEnCursoScreen(
                nombreAfiliado: args['nombreAfiliado'] ?? '',
                numeroAfiliacion: args['numeroAfiliacion'] ?? '',
                cuitEmpresa: args['cuitEmpresa'] ?? '',
                nombreEmpresa: args['nombreEmpresa'] ?? '',
              ),
            );

          case '/finalizar':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => FinalizarVisitaScreen(
                datosVisita: args,
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Ruta desconocida')),
              ),
            );
        }
      },
    );
  }
}
