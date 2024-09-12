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
      name: data[nameKey],
      description: data[descriptionKey],
      image: data[imageKey],
      url: data[urlKey],
      createdAt: data[GNCommonFields.createdAt].toDate(),
      updatedAt: data[GNCommonFields.updatedAt].toDate(),
    );
  }

  static const String collectionName = 'esports';

  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String imageKey = 'image';
  static const String urlKey = 'url';
}
