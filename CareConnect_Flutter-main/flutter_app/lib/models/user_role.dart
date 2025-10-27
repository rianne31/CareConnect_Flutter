enum UserRole {
  admin,
  donor,
  undefined;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'donor':
        return UserRole.donor;
      default:
        return UserRole.undefined;
    }
  }

  @override
  String toString() {
    return name.toLowerCase();
  }
}