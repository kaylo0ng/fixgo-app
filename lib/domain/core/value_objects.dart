import 'dart:math';

import 'package:fixgo/domain/core/result.dart';

abstract class ValueObject<T> {
  const ValueObject();
  T get value;

  @override
  bool operator ==(Object other) =>
      other is ValueObject<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ValueObject($value)';
}

abstract class ValidatedValueObject<T> extends ValueObject<T> {
  const ValidatedValueObject(this.value);
  @override final T value;
}

class Email extends ValidatedValueObject<String> {
  const Email(super.value);
  static Result<Email> create(String raw) {
    final v = raw.trim();
    if (!_regex.hasMatch(v)) return Result.err(InvalidEmail(v));
    return Result.ok(Email(v));
  }
  static final _regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  String get domain => value.split('@').last;
}

class Password extends ValidatedValueObject<String> {
  const Password(super.value);
  static Result<Password> create(String raw) {
    if (raw.length < 8) return Result.err(ShortPassword(raw));
    if (!RegExp(r'[A-Z]').hasMatch(raw)) return Result.err(WeakPassword(raw));
    if (!RegExp(r'[0-9]').hasMatch(raw)) return Result.err(WeakPassword(raw));
    return Result.ok(Password(raw));
  }
}

class Price extends ValidatedValueObject<double> {
  const Price(super.value);
  static Result<Price> create(double raw) {
    if (raw < 0) return Result.err(NegativePrice(raw.toString()));
    if (raw > 100000) return Result.err(ExcessivePrice(raw.toString()));
    return Result.ok(Price(raw));
  }
  String get formatted => '\$${value.toStringAsFixed(2)}';
  Price operator +(Price other) => Price(value + other.value);
  Price operator -(Price other) => Price(value - other.value);
  Price operator *(double factor) => Price(value * factor);
}

class DurationMinutes extends ValidatedValueObject<int> {
  const DurationMinutes(super.value);
  static Result<DurationMinutes> create(int raw) {
    if (raw <= 0) return Result.err(InvalidDuration(raw.toString()));
    if (raw > 1440) return Result.err(ExcessiveDuration(raw.toString()));
    return Result.ok(DurationMinutes(raw));
  }
  Duration get asDuration => Duration(minutes: value);
  int get hours => value ~/ 60;
  int get minutes => value % 60;
  @override String toString() {
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }
}

class Coordinates extends ValidatedValueObject<(double latitude, double longitude)> {
  const Coordinates(super.value);
  static Result<Coordinates> create(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) return Result.err(InvalidLatitude(latitude.toString()));
    if (longitude < -180 || longitude > 180) return Result.err(InvalidLongitude(longitude.toString()));
    return Result.ok(Coordinates((latitude, longitude)));
  }
  double get latitude => value.$1;
  double get longitude => value.$2;
  double distanceTo(Coordinates other) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(other.latitude - latitude);
    final dLon = _degToRad(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(latitude)) * cos(_degToRad(other.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
  double _degToRad(double deg) => deg * (pi / 180);
}

class RatingValue extends ValidatedValueObject<double> {
  const RatingValue(super.value);
  static Result<RatingValue> create(double raw) {
    if (raw < 1.0 || raw > 5.0) return Result.err(InvalidRating(raw.toString()));
    return Result.ok(RatingValue(raw));
  }
  int get stars => value.round();
}

class PhoneNumber extends ValidatedValueObject<String> {
  const PhoneNumber._(super.value);
  static Result<PhoneNumber> create(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return Result.err(InvalidPhoneNumber(raw));
    }
    return Result.ok(PhoneNumber._(digitsOnly));
  }
  String get formatted {
    if (value.length == 10) {
      return '(${value.substring(0, 3)}) ${value.substring(3, 6)}-${value.substring(6)}';
    }
    return value;
  }
}

class NonEmptyString extends ValidatedValueObject<String> {
  const NonEmptyString._(super.value);
  static Result<NonEmptyString> create(String raw, {int? maxLength}) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    if (maxLength != null && v.length > maxLength) {
      return Result.err(StringTooLong(v, maxLength));
    }
    return Result.ok(NonEmptyString._(v));
  }
}

class ServiceCategoryId extends ValidatedValueObject<String> {
  const ServiceCategoryId._(super.value);
  static Result<ServiceCategoryId> create(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    if (!_validCategories.contains(v)) {
      return Result.err(InvalidServiceCategory(v));
    }
    return Result.ok(ServiceCategoryId._(v));
  }
  static const _validCategories = {
    'plumbing', 'electrical', 'carpentry', 'painting', 'hvac',
    'appliance_repair', 'cleaning', 'gardening', 'masonry', 'roofing',
  };
}

class UserId extends ValidatedValueObject<String> {
  const UserId._(super.value);
  static Result<UserId> create(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    return Result.ok(UserId._(v));
  }
}

class RequestId extends ValidatedValueObject<String> {
  const RequestId._(super.value);
  static Result<RequestId> create(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    return Result.ok(RequestId._(v));
  }
}

class OfferId extends ValidatedValueObject<String> {
  const OfferId._(super.value);
  static Result<OfferId> create(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    return Result.ok(OfferId._(v));
  }
}

class TechnicianId extends ValidatedValueObject<String> {
  const TechnicianId._(super.value);
  static Result<TechnicianId> create(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return Result.err(EmptyString(v));
    return Result.ok(TechnicianId._(v));
  }
}