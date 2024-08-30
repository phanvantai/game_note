class GNCollection {
  static const String users = 'users';

  static const String communities = 'communities';
  static const String feedbacks = 'feedbacks';
}

class GNUserFields {
  static const String displayName = 'displayName';
  static const String phoneNumber = 'phoneNumber';
  static const String email = 'email';
  static const String photoUrl = 'photoUrl';
}

class GNCommunityFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String owner = 'owner';
  static const String members = 'members';
}

class GNFeedbackFields {
  static const String title = 'title';
  static const String detail = 'detail';
  static const String status = 'status';
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}
