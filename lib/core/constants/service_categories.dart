import 'package:fixgo/domain/category/service_category.dart';

class ServiceCategories {
  const ServiceCategories._();

  static final values = <ServiceCategory>[
    ServiceCategory.create(
      id: 'air_conditioning',
      name: 'Aire acondicionado',
      iconName: 'air_conditioning',
      description: 'Instalación, revisión y mantenimiento de equipos.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'electricity',
      name: 'Electricidad',
      iconName: 'electricity',
      description: 'Reparaciones, puntos eléctricos e instalaciones básicas.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'plumbing',
      name: 'Plomería',
      iconName: 'plumbing',
      description: 'Fugas, tuberías, grifería y mantenimiento.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'maintenance',
      name: 'Mantenimiento',
      iconName: 'maintenance',
      description: 'Arreglos generales y soporte para el hogar.',
    ).getOrThrow(),
  ];
}