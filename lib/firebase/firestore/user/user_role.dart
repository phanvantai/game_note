enum UserRole {
  admin,
  user,
}

extension ParseToString on UserRole {
  String get name {
    return toString().split('.').last;
  }
}
