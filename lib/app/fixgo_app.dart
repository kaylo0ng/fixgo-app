import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/app/theme/app_theme.dart';
import 'package:fixgo/features/home/presentation/home_screen.dart';
import 'package:fixgo/l10n/app_localizations.dart';

class FixGoApp extends ConsumerStatefulWidget {
  const FixGoApp({super.key});

  @override
  ConsumerState<FixGoApp> createState() => _FixGoAppState();
}

class _FixGoAppState extends ConsumerState<FixGoApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      restorationScopeId: 'app',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}