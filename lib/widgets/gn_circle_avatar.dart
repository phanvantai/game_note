import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GNCircleAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  const GNCircleAvatar({super.key, this.photoUrl, this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name?.trim().isNotEmpty == true ? name!.trim()[0].toUpperCase() : null;
    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null
            ? initial != null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: colorScheme.onSurface,
                  )
            : null,
      ),
    );
  }
}
