import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/features/technician/presentation/technician_view.dart';

class TechnicianScreen extends ConsumerWidget {
  const TechnicianScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar como técnico')),
      body: const TechnicianView(),
    );
  }
}