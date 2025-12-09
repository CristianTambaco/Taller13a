import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'cubits/chat_cubit.dart';
import 'services/gemini_service.dart';
import 'screems/chat_screen.dart';

/// Punto de entrada de la aplicacion.
///
/// main() es la funcion que Flutter ejecuta primero.
/// runApp() inicializa el framework y muestra el widget raiz.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // create: funcion que crea la instancia del Cubit
      // Se ejecuta una sola vez cuando se monta el provider
      // Inyectamos GeminiService al Cubit (Dependency Injection)
      create: (context) => ChatCubit(GeminiService()),
      child: MaterialApp(
        title: 'Gemini Chat',
        debugShowCheckedModeBanner: false, // Quita la etiqueta "DEBUG"
        // Configuracion del tema visual
        theme: ThemeData(
          // Usamos Material 3 (el mas reciente)
          useMaterial3: true,
          // Generamos el esquema de colores desde un color semilla
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ), // ColorScheme.fromSeed
        ), // ThemeData
        // Pantalla inicial
        home: const ChatScreen(),
      ), // MaterialApp
    ); // BlocProvider
  }
}
