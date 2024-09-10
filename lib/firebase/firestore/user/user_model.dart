import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../gn_collection.dart';

class UserModel extends Equatable {
  final String id;
  final String? displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String role;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.photoUrl,
    required this.role,
  });

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      id: snapshot.id,
      displayName: data[GNUserFields.displayName],
      phoneNumber: data[GNUserFields.phoneNumber],
      email: data[GNUserFields.email],
      photoUrl: data[GNUserFields.photoUrl],
      role: data[GNUserFields.role],
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, phoneNumber, email, photoUrl, role];
}
