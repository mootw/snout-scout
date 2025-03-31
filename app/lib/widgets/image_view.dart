import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

///TODO this is a TERRIBLE implementation haha
class ImageViewer extends StatelessWidget {
  final Image child;

  const ImageViewer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: child,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  appBar: AppBar(),
                  body: PhotoView(
                    filterQuality: FilterQuality.medium,
                    imageProvider: child.image,
                  ),
                ),
          ),
        );
      },
    );
  }
}
