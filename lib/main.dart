import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/accueil_shell.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: CalculElectriqueApp()));
}

class CalculElectriqueApp extends StatelessWidget {
  const CalculElectriqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcul Électrique Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clair(),
      darkTheme: AppTheme.sombre(),
      home: const AccueilShell(),
    );
  }
}
