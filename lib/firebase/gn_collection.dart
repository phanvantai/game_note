class GNCollection {
  static const String users = 'users';
  static const String avatars = 'avatars';
  static const String communities = 'communities';
  static const String feedbacks = 'feedbacks';

  static const String esports = 'esports';
  static const String invitations = 'invitations';
  static const String teams = 'teams';
}

class GNCommonFields {
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class GNUserFields {
  static const String role = 'role';
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
}

class GNEsportFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String image = 'image';
  static const String url = 'url';
}

class GNInvitationFields {
  static const String invitationId = 'invitationId';
  static const String userId = 'userId';
  static const String status = 'status';
  static const String sentAt = 'sentAt';
  static const String respondedAt = 'respondedAt';
  static const String message = 'message';
}

class GNTeamFields {
  static const String teamId = 'teamId';
  static const String name = 'name';
  static const String ownerId = 'ownerId';
  static const String members = 'members';
  static const String managers = 'managers';
}
