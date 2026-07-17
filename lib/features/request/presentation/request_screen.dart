import 'package:flutter/material.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar solicitud')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe el trabajo que necesitas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aquí podrás publicar tu solicitud, subir fotos y recibir ofertas de técnicos.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitud creada correctamente.')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Crear solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
