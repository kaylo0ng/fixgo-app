import 'package:flutter/material.dart';

import 'package:fixgo/core/constants/service_categories.dart';
import 'package:fixgo/features/home/presentation/widgets/service_category_chip.dart';
import 'package:fixgo/features/request/presentation/request_screen.dart';
import 'package:fixgo/features/technician/presentation/technician_screen.dart';
import 'package:fixgo/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              localizations.homeTitle,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.homeSubtitle,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const RequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded),
              label: Text(localizations.postRequestButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const TechnicianScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.engineering_rounded),
              label: Text(localizations.technicianLoginButton),
            ),
            const SizedBox(height: 28),
            Text(localizations.mainCategoriesTitle, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final category in ServiceCategories.values)
                  ServiceCategoryChip(label: category.name),
              ],
            ),
            const SizedBox(height: 28),
            _ServiceFlowCard(localizations: localizations),
          ],
        ),
      ),
    );
  }
}

class _ServiceFlowCard extends StatelessWidget {
  const _ServiceFlowCard({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.mvpFlowTitle, style: textTheme.titleLarge),
            const SizedBox(height: 14),
            _FlowStep(
              icon: Icons.assignment_rounded,
              title: localizations.requestPublished,
              description: localizations.requestPublishedDescription,
            ),
            _FlowStep(
              icon: Icons.local_offer_rounded,
              title: localizations.offersReceived,
              description: localizations.offersReceivedDescription,
            ),
            _FlowStep(
              icon: Icons.verified_user_rounded,
              title: localizations.technicianSelected,
              description: localizations.technicianSelectedDescription,
            ),
            _FlowStep(
              icon: Icons.star_rounded,
              title: localizations.serviceRated,
              description: localizations.serviceRatedDescription,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: colorScheme.primary,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(description, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
