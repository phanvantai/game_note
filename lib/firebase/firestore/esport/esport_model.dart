import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_note/firebase/gn_collection.dart';

class EsportModel {
  final String id;
  final String? name;
  final String? description;
  final String? image;
  final String? url;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EsportModel({
    required this.id,
    this.name,
    this.description,
    this.image,
    this.url,
    this.createdAt,
    this.updatedAt,
  });

  factory EsportModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return EsportModel(
      id: snapshot.id,
      name: data[GNEsportFields.name],
      description: data[GNEsportFields.description],
      image: data[GNEsportFields.image],
      url: data[GNEsportFields.url],
      createdAt: data[GNCommonFields.createdAt].toDate(),
      updatedAt: data[GNCommonFields.updatedAt].toDate(),
    );
  }
}
