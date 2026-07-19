import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixgo/application/technician/technician_viewmodel.dart';

class TechnicianView extends ConsumerWidget {
  const TechnicianView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianViewModelProvider);

    return stateWhen(
      value: (state) => _buildContent(context, state),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(technicianViewModelProvider.notifier).loadProfile('current_user_id'),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TechnicianState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu perfil de técnico')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu perfil de técnico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Completa tu información para empezar a recibir solicitudes.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(technicianViewModelProvider);
                  return FilledButton.icon(
                    onPressed: state.isSubmitting ? null : () => _showProfileForm(context, ref),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(state.isSubmitting
                        ? 'Completando perfil...'
                        : 'Completar perfil'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TechnicianProfileForm(),
    );
  }
}

class _TechnicianProfileForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TechnicianProfileForm> createState() => _TechnicianProfileFormState();
}

class _TechnicianProfileFormState extends ConsumerState<_TechnicianProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _radiusController = TextEditingController(text: '20');
  String? _selectedCategory;

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianViewModelProvider);
    final categories = ref.watch(homeViewModelProvider).value?.categories ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Perfil de técnico',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categoría principal',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: [
                  for (final cat in ServiceCategories.values)
                    DropdownMenuItem(value: cat.id.value, child: Text(cat.name.value)),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  hintText: 'Describe tu experiencia y habilidades...',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La biografía es requerida';
                  }
                  if (value.trim().length < 20) {
                    return 'La biografía debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tarifa por hora (MXN)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu tarifa';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Radio de servicio (km)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.map_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un radio';
                  final num = int.tryParse(value);
                  if (num == null || num < 1 || num > 100) {
                    return 'Radio entre 1 y 100 km';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(technicianViewModelProvider);
                  return FilledButton.icon(
                    onPressed: state.isSubmitting ? null : _submit,
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(state.isSubmitting ? 'Creando perfil...' : 'Crear perfil'),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = ref.read(technicianViewModelProvider.notifier).createProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id',
      bio: _bioController.text.trim(),
      categoryIds: [_selectedCategory!],
      latitude: 19.4326,
      longitude: -99.1332,
      hourlyRate: double.parse(_hourlyRateController.text),
      availabilityRadiusKm: int.parse(_radiusController.text),
    );

    result.fold(
      (saved) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil de técnico creado correctamente')),
        );
      },
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }
}