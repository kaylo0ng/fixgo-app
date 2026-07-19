import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/application/service_request/service_request_state.dart';
import 'package:fixgo/application/service_request/service_request_viewmodel.dart';
import 'package:fixgo/application/providers/repositories.dart';
import 'package:fixgo/l10n/app_localizations.dart';

class RequestView extends ConsumerWidget {
  const RequestView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceRequestViewModelProvider);
    final notifier = ref.read(serviceRequestViewModelProvider.notifier);
    final localizations = AppLocalizations.of(context);

    return state.when(
      data: (state) => _buildContent(context, ref, state, notifier, localizations),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ServiceRequestState state,
    ServiceRequestViewModel notifier,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(localizations.postRequestButton)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            child: ListView(
              children: [
                Text(
                  localizations.requestDescriptionTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.requestDescriptionSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localizations.requestTitleLabel,
                    hintText: localizations.requestTitleHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.validationRequired;
                    }
                    if (value.trim().length < 5) {
                      return localizations.validationMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: localizations.requestDescriptionLabel,
                    hintText: localizations.requestDescriptionHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.validationRequired;
                    }
                    if (value.trim().length < 20) {
                      return localizations.validationMinLengthLong;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localizations.requestAddressLabel,
                    hintText: localizations.requestAddressHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.isSubmitting ? null : () => _submit(notifier),
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: Text(state.isSubmitting
                      ? localizations.requestCreating
                      : localizations.requestCreateButton),
                ),
                if (state.successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.successMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

  void _submit(ServiceRequestViewModel notifier) async {
    // For now, we'll use placeholder values. In a real app, these would come from form controllers.
    final result = await notifier.createRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: 'current_user_id', // Would come from auth state
      categoryId: 'plumbing', // Would come from category selection
      title: 'Sample Request', // Would come from form field
      description: 'Sample description', // Would come from form field
      address: 'Sample address', // Would come from form field
      latitude: 19.4326,
      longitude: -99.1332,
    );

    if (result.isOk) {
      // Navigate to success screen or show success
    }
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(serviceRequestViewModelProvider.notifier);
    final localizations = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: localizations.requestTitleLabel,
              hintText: localizations.requestTitleHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return localizations.validationRequired;
              }
              if (value.trim().length < 5) {
                return localizations.validationMinLength;
              }
              return null;
            },
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localizations.requestDescriptionLabel,
            hintText: localizations.requestDescriptionHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.description_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.validationRequired;
            }
            if (value.trim().length < 20) {
              return localizations.validationMinLengthLong;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: localizations.requestAddressLabel,
            hintText: localizations.requestAddressHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.validationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(serviceRequestViewModelProvider);
            return FilledButton.icon(
              onPressed: state.isSubmitting ? null : () => _submit(notifier),
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(state.isSubmitting
                  ? localizations.requestCreating
                  : localizations.requestCreateButton),
            );
          },
        ),
      ],
    );
  }

  void _submit(ServiceRequestViewModel notifier) {
    if (!_formKey.currentState!.validate()) return;

    notifier.createRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: 'current_user_id',
      categoryId: 'plumbing',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      latitude: 19.4326,
      longitude: -99.1332,
    );
  }
}