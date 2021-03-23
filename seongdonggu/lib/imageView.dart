import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'common/stringConstant.dart';

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
    return Stack(
      alignment: Alignment.center,
      children: [
        PhotoView(
            imageProvider: CachedNetworkImageProvider(_image),
            enableRotation: true),
        Align(
          alignment: Alignment.bottomCenter,
          child: Card(
              margin: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    StringClass.OK,
                    style: TextStyle(color: Colors.blue),
                  ))),
        )
      ],
    );
  }
}
