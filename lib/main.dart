import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Arquivo gerado pelo flutterfire configure
import 'screens/home_screen.dart';

void main() async {
  // 1. Garante que a binding do Flutter esteja pronta
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Firebase com a configuração da sua plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogo de Cartas',
      theme: ThemeData(primarySwatch: Colors.green),
      home: GameHomeScreen(), // Vamos criar essa tela em breve
    );
  }
}