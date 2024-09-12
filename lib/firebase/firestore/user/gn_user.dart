import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GNUser extends Equatable {
  final String id;
  final String? displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String role;

  const GNUser({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.photoUrl,
    required this.role,
  });

  factory GNUser.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return GNUser(
      id: snapshot.id,
      displayName: data[displayNameKey],
      phoneNumber: data[phoneNumberKey],
      email: data[emailKey],
      photoUrl: data[photoUrlKey],
      role: data[roleKey],
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, phoneNumber, email, photoUrl, role];

  static const String collectionName = 'users';

  static const String idKey = 'id';
  static const String displayNameKey = 'displayName';
  static const String roleKey = 'role';
  static const String phoneNumberKey = 'phoneNumber';
  static const String emailKey = 'email';
  static const String photoUrlKey = 'photoUrl';
}
