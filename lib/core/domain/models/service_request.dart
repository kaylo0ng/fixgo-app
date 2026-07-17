import 'package:fixgo/core/domain/enums/service_request_status.dart';

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.createdAt,
    this.selectedOfferId,
    this.scheduledAt,
    this.completedAt,
    this.cancelledAt,
  });

  final String id;
  final String clientId;
  final String categoryId;
  final String title;
  final String description;
  final String address;
  final ServiceRequestStatus status;
  final DateTime createdAt;
  final String? selectedOfferId;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  bool get isOpen {
    return status == ServiceRequestStatus.published ||
        status == ServiceRequestStatus.receivingOffers;
  }

  bool get isFinished {
    return status == ServiceRequestStatus.completed ||
        status == ServiceRequestStatus.rated ||
        status == ServiceRequestStatus.cancelled;
  }
}
