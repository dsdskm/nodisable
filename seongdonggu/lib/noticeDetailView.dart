import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/util.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';

class NoticeDetailView extends StatelessWidget {
  static String route = "/noticeDetailView";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => NoticeDetailViewWidget("")
    }, home: NoticeDetailViewWidget(""));
  }
}

class NoticeDetailViewWidget extends StatefulWidget {
  String _docu;

  NoticeDetailViewWidget(this._docu);

  @override
  NoticeDetailViewState createState() => NoticeDetailViewState(_docu);
}

class NoticeDetailViewState extends State<NoticeDetailViewWidget> {
  TextEditingController _commentController = TextEditingController();
  String _docu = "";

  NoticeDetailViewState(this._docu);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(StringClass.NOTICE)),
        body: Center(
            child: Container(
          child: FutureBuilder(
            future: DATABASE.noticeDao.getNotice(_docu),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                NoticeData data = snapshot.data;
                String title = data.title;
                String content = data.content;
                return Container(
                    padding: EdgeInsets.all(20),
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )),
                        Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        Container(
                          alignment: Alignment.topRight,
                          child: Text(getDateText(int.parse(data.docu))),
                        ),
                        Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            content,
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.normal),
                          ),
                        ),
                        Image.network(data.image)
                      ],
                    ));
              }
              return Container();
            },
          ),
        )));
  }

  @override
  void dispose() {
    super.dispose();
    _commentController.clear();
  }

}
