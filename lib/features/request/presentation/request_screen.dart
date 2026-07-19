import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/features/request/presentation/request_view.dart';

class RequestScreen extends ConsumerWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar solicitud')),
      body: const RequestView(),
    );
  }
}