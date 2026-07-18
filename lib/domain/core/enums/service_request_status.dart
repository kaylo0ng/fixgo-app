enum ServiceRequestStatus {
  published,
  receivingOffers,
  technicianSelected,
  inProgress,
  pendingConfirmation,
  completed,
  rated,
  cancelled,
}

extension ServiceRequestStatusLabel on ServiceRequestStatus {
  String get label {
    return switch (this) {
      ServiceRequestStatus.published => 'Publicado',
      ServiceRequestStatus.receivingOffers => 'Recibiendo ofertas',
      ServiceRequestStatus.technicianSelected => 'Técnico seleccionado',
      ServiceRequestStatus.inProgress => 'En curso',
      ServiceRequestStatus.pendingConfirmation => 'Pendiente de confirmación',
      ServiceRequestStatus.completed => 'Finalizado',
      ServiceRequestStatus.rated => 'Calificado',
      ServiceRequestStatus.cancelled => 'Cancelado',
    };
  }
}
