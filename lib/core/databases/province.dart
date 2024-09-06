import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

class Province extends Equatable {
  final String id;
  final String name;

  const Province({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['idProvince'],
      name: json['name'],
    );
  }

  Province copyWith({
    String? id,
    String? name,
  }) {
    return Province(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class District extends Equatable {
  final String id;
  final String name;
  final String idProvince;

  const District({
    required this.id,
    required this.name,
    required this.idProvince,
  });

  @override
  List<Object?> get props => [id, name, idProvince];

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['idDistrict'],
      name: json['name'],
      idProvince: json['idProvince'],
    );
  }

  District copyWith({
    String? id,
    String? name,
    String? idProvince,
  }) {
    return District(
      id: id ?? this.id,
      name: name ?? this.name,
      idProvince: idProvince ?? this.idProvince,
    );
  }
}

class Commune extends Equatable {
  final String id;
  final String name;
  final String idDistrict;

  const Commune({
    required this.id,
    required this.name,
    required this.idDistrict,
  });

  @override
  List<Object?> get props => [id, name, idDistrict];

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['idCommune'],
      name: json['name'],
      idDistrict: json['idDistrict'],
    );
  }
}

List<Province> provinces = [];
List<District> districts = [];
List<Commune> communes = [];

Future<void> getProvinces() async {
  // Load the file from the assets folder
  String jsonString = await rootBundle.loadString('assets/province.json');

  // Decode the JSON string into a Map
  Map<String, dynamic> jsonData = json.decode(jsonString);

  final List<dynamic> provincesJson = jsonData['province'];
  final List<dynamic> districtsJson = jsonData['district'];
  final List<dynamic> communesJson = jsonData['commune'];

  communes = communesJson.map((e) => Commune.fromJson(e)).toList();

  districts = districtsJson.map((e) => District.fromJson(e)).toList();

  provinces = provincesJson.map((e) => Province.fromJson(e)).toList();

  print(provinces);
  print(districts);
  print(communes);
}
