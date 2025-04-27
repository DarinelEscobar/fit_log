import 'package:flutter/material.dart';
import 'navigation/main_scaffold.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fit Log',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainScaffold(),
    );
  }
}