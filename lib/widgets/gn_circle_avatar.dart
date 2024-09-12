import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GNCircleAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const GNCircleAvatar({
    Key? key,
    this.photoUrl,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(photoUrl);
    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundImage:
            photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
        child: photoUrl == null
            ? const Icon(
                Icons.person,
                color: Colors.black,
              )
            : null,
      ),
    );
  }
}
