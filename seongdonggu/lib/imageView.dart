import 'package:flutter/material.dart';

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
    return Container(child: Image.network(_image));
  }
}
