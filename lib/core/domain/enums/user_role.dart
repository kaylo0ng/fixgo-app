enum UserRole { client, technician }

extension UserRoleLabel on UserRole {
  String get label {
    return switch (this) {
      UserRole.client => 'Cliente',
      UserRole.technician => 'Técnico',
    };
  }
}
