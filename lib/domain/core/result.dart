sealed class Result<T> {
  const Result();

  T get value => throw StateError('Not an Ok result');
  Failure get failure => throw StateError('Not an Err result');

  T getOrThrow() => switch (this) {
    Ok(value: final v) => v,
    Err(failure: final f) => throw f,
  };

  T? getOrNull() => switch (this) {
    Ok(value: final v) => v,
    Err() => null,
  };

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) => switch (this) {
    Ok(value: final v) => onOk(v),
    Err(failure: final f) => onErr(f),
  };

  Result<U> map<U>(U Function(T value) transform) => switch (this) {
    Ok(value: final v) => Ok(transform(v)),
    Err(failure: final f) => Err(f),
  };

  Future<Result<U>> mapAsync<U>(Future<U> Function(T value) transform) async {
    switch (this) {
      case Ok(value: final v):
        try { return Ok(await transform(v)); }
        catch (e, st) { return Err(UnknownFailure(e.toString(), st)); }
      case Err(failure: final f):
        return Err(f);
    }
  }

  Result<T> onError(void Function(Failure failure) handler) {
    switch (this) {
      case Err(failure: final f):
        handler(f);
        return this;
      case Ok():
        return this;
    }
  }

  static Ok<T> ok<T>(T value) => Ok(value);
  static Err<T> err<T>(Failure failure) => Err(failure);
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  @override final T value;
  @override bool operator ==(Object other) => other is Ok<T> && other.value == value;
  @override int get hashCode => value.hashCode;
  @override String toString() => 'Ok($value)';
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  @override final Failure failure;
  @override bool operator ==(Object other) => other is Err<T> && other.failure == failure;
  @override int get hashCode => failure.hashCode;
  @override String toString() => 'Err($failure)';
}

abstract class Failure {
  const Failure();
  String get message => toString();
}

abstract class ValueFailure extends Failure {
  const ValueFailure(this.failedValue);
  final String failedValue;
}

class InvalidEmail extends ValueFailure { const InvalidEmail(super.v); @override String get message => 'Email inválido: $failedValue'; }
class ShortPassword extends ValueFailure { const ShortPassword(super.v); @override String get message => 'La contraseña debe tener al menos 8 caracteres'; }
class WeakPassword extends ValueFailure { const WeakPassword(super.v); @override String get message => 'La contraseña debe contener mayúsculas y números'; }
class NegativePrice extends ValueFailure { const NegativePrice(super.v); @override String get message => 'El precio no puede ser negativo'; }
class ExcessivePrice extends ValueFailure { const ExcessivePrice(super.v); @override String get message => 'El precio excede el límite máximo permitido'; }
class InvalidLatitude extends ValueFailure { const InvalidLatitude(super.v); @override String get message => 'Latitud inválida: $failedValue (debe estar entre -90 y 90)'; }
class InvalidLongitude extends ValueFailure { const InvalidLongitude(super.v); @override String get message => 'Longitud inválida: $failedValue (debe estar entre -180 y 180)'; }
class InvalidDuration extends ValueFailure { const InvalidDuration(super.v); @override String get message => 'La duración debe ser mayor a 0'; }
class ExcessiveDuration extends ValueFailure { const ExcessiveDuration(super.v); @override String get message => 'La duración no puede exceder 24 horas'; }
class InvalidRating extends ValueFailure { const InvalidRating(super.v); @override String get message => 'La calificación debe estar entre 1.0 y 5.0'; }
class InvalidPhoneNumber extends ValueFailure { const InvalidPhoneNumber(super.v); @override String get message => 'Número de teléfono inválido: $failedValue'; }
class EmptyString extends ValueFailure { const EmptyString(super.v); @override String get message => 'El valor no puede estar vacío'; }
class StringTooLong extends ValueFailure { final int maxLength; const StringTooLong(super.v, this.maxLength); @override String get message => 'El texto excede los $maxLength caracteres permitidos'; }
class InvalidCoordinates extends ValueFailure { const InvalidCoordinates(super.v); @override String get message => 'Coordenadas inválidas: $failedValue'; }
class InvalidServiceCategory extends ValueFailure { const InvalidServiceCategory(super.v); @override String get message => 'Categoría de servicio inválida: $failedValue'; }

class RepositoryFailure extends Failure { const RepositoryFailure(this.message, [this.cause]); @override final String message; final Object? cause; @override bool operator ==(Object other) => other is RepositoryFailure && other.message == message && other.cause == cause; @override int get hashCode => Object.hash(message, cause); }
class NetworkFailure extends Failure { const NetworkFailure(this.message, [this.cause]); @override final String message; final Object? cause; @override bool operator ==(Object other) => other is NetworkFailure && other.message == message && other.cause == cause; @override int get hashCode => Object.hash(message, cause); }
class AuthenticationFailure extends Failure { const AuthenticationFailure(this.message); @override final String message; @override bool operator ==(Object other) => other is AuthenticationFailure && other.message == message; @override int get hashCode => message.hashCode; }
class AuthorizationFailure extends Failure { const AuthorizationFailure(this.message); @override final String message; @override bool operator ==(Object other) => other is AuthorizationFailure && other.message == message; @override int get hashCode => message.hashCode; }
class NotFoundFailure extends Failure { const NotFoundFailure(this.resource, this.id); @override String get message => '$resource no encontrado: $id'; final String resource; final String id; @override bool operator ==(Object other) => other is NotFoundFailure && other.resource == resource && other.id == id; @override int get hashCode => Object.hash(resource, id); }
class ValidationFailure extends Failure { const ValidationFailure(this.failures); @override String get message => 'Errores de validación: ${failures.map((f) => f.message).join('; ')}'; final List<ValueFailure> failures; @override bool operator ==(Object other) => other is ValidationFailure && other.failures.length == failures.length && other.failures.toSet().containsAll(failures.toSet()); @override int get hashCode => Object.hashAll(failures); }
class UnknownFailure extends Failure { const UnknownFailure(this.message, [this.stackTrace]); @override final String message; final StackTrace? stackTrace; @override bool operator ==(Object other) => other is UnknownFailure && other.message == message && other.stackTrace == stackTrace; @override int get hashCode => Object.hash(message, stackTrace); }