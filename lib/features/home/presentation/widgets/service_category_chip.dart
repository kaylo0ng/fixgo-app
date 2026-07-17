import 'package:flutter/material.dart';

class ServiceCategoryChip extends StatelessWidget {
  const ServiceCategoryChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      label: Text(label),
      avatar: Icon(
        Icons.home_repair_service_rounded,
        color: colorScheme.primary,
        size: 18,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
