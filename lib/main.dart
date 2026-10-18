import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/historico_service.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PlantCareApp());
}

class PlantCareApp extends StatefulWidget {
  const PlantCareApp({super.key});

  @override
  State<PlantCareApp> createState() => _PlantCareAppState();
}

class _PlantCareAppState extends State<PlantCareApp> {
  bool modoEscuro = false;
  String nomeUsuario = 'Michelle';

  void alterarTema(bool valor) {
    setState(() {
      modoEscuro = valor;
    });

    registrarHistorico(
      'Tema alterado',
      detalhes: valor ? 'Modo escuro ativado.' : 'Modo claro ativado.',
    );
  }

  void alterarNome(String novoNome) {
    setState(() {
      nomeUsuario = novoNome;
    });

    registrarHistorico(
      'Perfil atualizado',
      detalhes: 'Nome de exibição alterado para $novoNome.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlantCare',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF5F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4758D),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF24191D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4758D),
          brightness: Brightness.dark,
        ),
      ),

      themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,

      home: LoginPage(
        modoEscuro: modoEscuro,
        alterarTema: alterarTema,
        nomeUsuario: nomeUsuario,
        alterarNome: alterarNome,
      ),
    );
  }
}
