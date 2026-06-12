import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const AntiTamperApp());
}

class AntiTamperApp extends StatelessWidget {
  const AntiTamperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti Tamper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
