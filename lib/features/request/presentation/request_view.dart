import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/core/constants/service_categories.dart';
import 'package:fixgo/l10n/app_localizations.dart';
import 'package:fixgo/application/service_request/service_request_state.dart';
import 'package:fixgo/application/service_request/service_request_viewmodel.dart';

class RequestView extends ConsumerWidget {
  const RequestView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceRequestViewModelProvider);

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      loaded: (state) => _buildContent(context, ref, state),
      error: (error) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ServiceRequestLoaded state,
  ) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar solicitud')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _RequestCreationForm(),
        ),
      ),
    );
  }
}

class _RequestCreationForm extends ConsumerStatefulWidget {
  const _RequestCreationForm();

  @override
  ConsumerState<_RequestCreationForm> createState() => _RequestCreationFormState();
}

class _RequestCreationFormState extends ConsumerState<_RequestCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final notifier = ref.read(serviceRequestViewModelProvider.notifier);

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Categoría',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_rounded),
            ),
            items: [
              for (final cat in ServiceCategories.values)
                DropdownMenuItem(value: cat.id, child: Text(cat.name.value)),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) => value == null ? 'Selecciona una categoría' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título',
              hintText: 'Describe brevemente el trabajo',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es requerido';
              }
              if (value.trim().length < 5) {
                return 'El título debe tener al menos 5 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Describe el trabajo que necesitas...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.description_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              if (value.trim().length < 20) {
                return 'La descripción debe tener al menos 20 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Dirección',
              hintText: 'Calle, número, colonia, ciudad',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La dirección es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(serviceRequestViewModelProvider);
              return state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (state) => FilledButton.icon(
                  onPressed: state.isSubmitting ? null : _submit,
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: Text(state.isSubmitting
                      ? 'Creando solicitud...'
                      : 'Crear solicitud'),
                ),
                error: (error) => FilledButton.icon(
                  onPressed: () => _submit(),
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text('Error: $error'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(serviceRequestViewModelProvider.notifier).createRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: 'current_user_id',
      categoryId: _selectedCategory!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      latitude: 19.4326,
      longitude: -99.1332,
    );
  }
}

final _formKey = GlobalKey<FormState>();
final _titleController = TextEditingController();
final _descriptionController = TextEditingController();
final _addressController = TextEditingController();
String? _selectedCategory;

final serviceRequestViewModelProvider = StateNotifierProvider<ServiceRequestViewModel, dynamic>(
  (ref) => throw UnimplementedError(),
);