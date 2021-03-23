import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatelessWidget {
  static String route = "/imageView";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => ImageViewWidget("")
    }, home: ImageViewWidget(""));
  }
}

class ImageViewWidget extends StatefulWidget {
  String _image;

  ImageViewWidget(this._image);

  @override
  ImageViewState createState() => ImageViewState(_image);
}

class ImageViewState extends State<ImageViewWidget> {
  String _image;

  ImageViewState(this._image);

  @override
  Widget build(BuildContext context) {
    // return Container(child: Image.network(_image));
    return PhotoView(imageProvider: CachedNetworkImageProvider(_image),
      enableRotation: true);
  }
}
