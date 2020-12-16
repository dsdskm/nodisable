import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("후기 작성")),
      body: Center(
          child: Container(
              child: Column(
        children: [
          Text("후기를 작성해주세요"),
          Container(
              child: TextFormField(
                controller: _commentController,
            decoration: InputDecoration(hintText: "내용을 입력해주세요"),
          )),
          Container(
            child: FlatButton(
              child:Text("보내기"),
              onPressed: (){

              },
            )
          )
        ],
      ))),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _commentController.clear();
  }
}
