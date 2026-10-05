import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'providers/database_provider.dart';
import 'providers/security_provider.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/home_shell.dart';

class GestionFinancesApp extends ConsumerStatefulWidget {
  const GestionFinancesApp({super.key});

  @override
  ConsumerState<GestionFinancesApp> createState() => _GestionFinancesAppState();
}

class _GestionFinancesAppState extends ConsumerState<GestionFinancesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Crée les catégories par défaut au tout premier lancement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryRepositoryProvider).seedDefaultCategoriesIfEmpty();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      ref.read(securityProvider.notifier).onAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);

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
      builder: (context, child) {
        if (!securityState.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final showLock = securityState.shouldShowLockScreen;

        return Stack(
          children: [
            if (child != null)
              FocusScope(
                canRequestFocus: !showLock,
                child: TickerMode(
                  enabled: !showLock,
                  child: IgnorePointer(
                    ignoring: showLock,
                    child: child,
                  ),
                ),
              ),
            if (showLock)
              const Positioned.fill(
                child: LockScreen(),
              ),
          ],
        );
      },
      home: const HomeShell(),
    );
  }
}
