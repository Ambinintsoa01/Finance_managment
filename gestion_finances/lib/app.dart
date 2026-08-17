import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'providers/database_provider.dart';
import 'screens/home_shell.dart';

class GestionFinancesApp extends ConsumerStatefulWidget {
  const GestionFinancesApp({super.key});

  @override
  ConsumerState<GestionFinancesApp> createState() => _GestionFinancesAppState();
}

class _GestionFinancesAppState extends ConsumerState<GestionFinancesApp> {
  @override
  void initState() {
    super.initState();
    // Crée les catégories par défaut au tout premier lancement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryRepositoryProvider).seedDefaultCategoriesIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes Finances',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
