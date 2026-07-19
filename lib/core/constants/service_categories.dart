import 'package:fixgo/domain/category/service_category.dart';

class ServiceCategories {
  const ServiceCategories._();

  static final values = <ServiceCategory>[
    ServiceCategory.create(
      id: 'hvac',
      name: 'Aire acondicionado',
      iconName: 'air_conditioning',
      description: 'Instalación, revisión y mantenimiento de equipos.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'electrical',
      name: 'Electricidad',
      iconName: 'electrical',
      description: 'Reparaciones, puntos eléctricos e instalaciones básicas.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'plumbing',
      name: 'Plomería',
      iconName: 'plumbing',
      description: 'Fugas, tuberías, grifería y mantenimiento.',
    ).getOrThrow(),
    ServiceCategory.create(
      id: 'masonry',
      name: 'Mantenimiento',
      iconName: 'masonry',
      description: 'Arreglos generales y soporte para el hogar.',
    ).getOrThrow(),
  ];
}