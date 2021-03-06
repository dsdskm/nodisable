import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:launch_review/launch_review.dart';
import 'package:screen/screen.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';
import 'package:seongdonggu/noticeDetailView.dart';

import 'common/util.dart';

class CommentView extends StatelessWidget {
  static String route = "/commentView";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => CommentViewWidget()
    }, home: CommentViewWidget());
  }
}

class CommentViewWidget extends StatefulWidget {
  @override
  CommentViewState createState() => CommentViewState();
}

class CommentViewState extends State<CommentViewWidget> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Screen.keepOn(true);
    return Scaffold(
        appBar: AppBar(title: Text(StringClass.COMMENT)),
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: StringClass.COMMENT_HINT,
                  )),
              Container(
                padding: EdgeInsets.all(10),
                child: Text(StringClass.CONTACT_EMAIL,
                    textAlign: TextAlign.center),
              ),
              Container(
                margin: const EdgeInsets.all(5.0),
                padding: const EdgeInsets.all(5.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                child: FlatButton(
                  child: Text(StringClass.SEND),
                  onPressed: () {
                    showConfirmDialog();
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrangeAccent)),
                child: FlatButton(
                  child: Text(Platform.isAndroid
                      ? StringClass.GO_MARKET
                      : StringClass.GO_APPSTORE),
                  onPressed: () {
                    LaunchReview.launch(
                        androidAppId: "com.kkh.seongdonggu",
                        iOSAppId: "1545829754");
                  },
                ),
              )
            ],
          ),
        ));
  }

  void showConfirmDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: new Text(StringClass.DIALOG_TITLE_COMMENT),
              content: new Text(StringClass.DIALOG_MESSAGE_COMMENT),
              actions: <Widget>[
                new FlatButton(
                  child: new Text(StringClass.YES),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                    sendComment();
                    _textController.clear();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                new FlatButton(
                  child: new Text(StringClass.NO),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  },
                ),
              ],
            ));
  }

  void sendComment() {
    print("sendComment");
    var docu = DateTime.now().millisecondsSinceEpoch.toString();
    Firestore.instance
        .collection(COLLECTION_COMMENT)
        .document(docu)
        .setData({FIELD_TEXT: _textController.text, FIELD_TIME: docu});
  }

  @override
  void dispose() {
    _textController.clear();
    _textController.dispose();
  }
}
