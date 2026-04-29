import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'captura_pie_screen.dart'; // ajusta el nombre según tu archivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await availableCameras(); // inicializa cámaras antes de arrancar
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pie App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A93BE)),
        useMaterial3: true,
      ),
      home: const CapturaPieScreen(),
    );
  }
}