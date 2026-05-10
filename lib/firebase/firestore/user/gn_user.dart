import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GNUser extends Equatable {
  final String id;
  final String? displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String role;
  final String fcmToken;
  final bool isPlaceholder;
  final bool deleted;
  final DateTime? deletedAt;

  static const String collectionName = 'users';

  static const String idKey = 'id';
  static const String displayNameKey = 'displayName';
  static const String roleKey = 'role';
  static const String phoneNumberKey = 'phoneNumber';
  static const String emailKey = 'email';
  static const String photoUrlKey = 'photoUrl';
  static const String fcmTokenKey = 'fcmToken';
  static const String isPlaceholderKey = 'isPlaceholder';
  static const String deletedKey = 'deleted';
  static const String deletedAtKey = 'deletedAt';

  const GNUser({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.fcmToken,
    this.isPlaceholder = false,
    this.deleted = false,
    this.deletedAt,
  });

  GNUser copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    String? role,
    String? fcmToken,
    bool? isPlaceholder,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return GNUser(
      id: id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      displayNameKey: displayName,
      phoneNumberKey: phoneNumber,
      emailKey: email,
      photoUrlKey: photoUrl,
      roleKey: role,
      fcmTokenKey: fcmToken,
      isPlaceholderKey: isPlaceholder,
      deletedKey: deleted,
      deletedAtKey: deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }

  factory GNUser.fromFireStore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return GNUser(
      id: snapshot.id,
      displayName: data[displayNameKey],
      phoneNumber: data[phoneNumberKey],
      email: data[emailKey],
      photoUrl: data[photoUrlKey],
      role: data[roleKey] ?? 'user',
      fcmToken: data[fcmTokenKey] ?? '',
      isPlaceholder: data[isPlaceholderKey] ?? false,
      deleted: data[deletedKey] ?? false,
      deletedAt: (data[deletedAtKey] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    phoneNumber,
    email,
    photoUrl,
    role,
    fcmToken,
    isPlaceholder,
    deleted,
    deletedAt,
  ];

  bool get isDeleted => deleted;
  String get effectiveDisplayName {
    final name = displayName ?? 'Người chơi';
    return deleted ? '$name (đã xoá)' : name;
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get isCurrentUser {
    try {
      return id == FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return false;
    }
  }
}
