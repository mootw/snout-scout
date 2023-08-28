import 'package:flutter/material.dart';

///TODO this is a TERRIBLE implementation haha
class ImageViewer extends StatelessWidget {
  final Widget child;

  const ImageViewer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: child,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Scaffold(
              appBar: AppBar(),
              body: InteractiveViewer(
                constrained: false,
                maxScale: 4,
                minScale: 0.1,
                child: child,
              )),
        ));
      },
    );
  }
}
