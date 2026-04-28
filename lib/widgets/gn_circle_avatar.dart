import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GNCircleAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const GNCircleAvatar({super.key, this.photoUrl, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null
            ? Icon(
                Icons.person,
                size: size * 0.6,
                color: Theme.of(context).colorScheme.onSurface,
              )
            : null,
      ),
    );
  }
}
