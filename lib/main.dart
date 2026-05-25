import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
    DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AsistenciaApp());
}

class AsistenciaApp extends StatelessWidget {
  const AsistenciaApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
      false,

      title:
      'Sistema de Asistencia',

      theme: ThemeData(
        colorSchemeSeed:
        Colors.indigo,
        useMaterial3: true,
      ),

      locale: const Locale(
        'es',
        'PE',
      ),

      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('es'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations
            .delegate,

        GlobalWidgetsLocalizations
            .delegate,

        GlobalCupertinoLocalizations
            .delegate,
      ],

      home: const AuthGate(),
    );
  }
}