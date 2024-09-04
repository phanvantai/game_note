import 'package:cloud_firestore/cloud_firestore.dart';

class GNFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;
}
