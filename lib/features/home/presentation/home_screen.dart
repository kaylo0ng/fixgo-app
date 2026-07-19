import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/features/home/presentation/home_view.dart';
import 'package:fixgo/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: const HomeView(),
    );
  }
}