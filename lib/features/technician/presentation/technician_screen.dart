import 'package:flutter/material.dart';

class TechnicianScreen extends StatelessWidget {
  const TechnicianScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar como técnico')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu perfil de técnico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aquí podrás registrarte, mostrar tu experiencia y recibir solicitudes de clientes.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil de técnico listo para completar.')),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Completar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
