import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/esport/gn_firestore_esport.dart';

import '../../../firebase/firestore/esport/esport_model.dart';
import '../../../firebase/firestore/gn_firestore.dart';
import '../../../injection_container.dart';

class PesTitle extends StatelessWidget {
  const PesTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EsportModel>>(
      future: getIt<GNFirestore>().getEsports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: snapshot.data!.first.image ?? '',
                  height: 32,
                ),
              ),
              const SizedBox(width: 8),
              Text(snapshot.data!.first.name ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
