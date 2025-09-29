import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/esport_model.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

extension GNFirestoreEsport on GNFirestore {
  Future<List<EsportModel>> getEsports() async {
    QuerySnapshot snapshot =
        await firestore.collection(EsportModel.collectionName).get();
    return snapshot.docs.map((doc) => EsportModel.fromFirestore(doc)).toList();
  }
}
