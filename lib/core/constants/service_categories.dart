import 'package:fixgo/core/domain/models/service_category.dart';

class ServiceCategories {
  const ServiceCategories._();

  static const values = <ServiceCategory>[
    ServiceCategory(
      id: 'air_conditioning',
      name: 'Aire acondicionado',
      description: 'Instalación, revisión y mantenimiento de equipos.',
    ),
    ServiceCategory(
      id: 'electricity',
      name: 'Electricidad',
      description: 'Reparaciones, puntos eléctricos e instalaciones básicas.',
    ),
    ServiceCategory(
      id: 'plumbing',
      name: 'Plomería',
      description: 'Fugas, tuberías, grifería y mantenimiento.',
    ),
    ServiceCategory(
      id: 'maintenance',
      name: 'Mantenimiento',
      description: 'Arreglos generales y soporte para el hogar.',
    ),
  ];
}
