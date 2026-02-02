import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/library_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner de Livres AR - Algérie',
      theme: ThemeData(
        primaryColor: const Color(0xFF38ada9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38ada9),
          secondary: const Color(0xFF3c6382),
        ),
        useMaterial3: true,
      ),
      home: const LibrarySelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
