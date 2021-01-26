import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';
import 'package:seongdonggu/noticeDetailView.dart';

import 'common/util.dart';

class NoticeView extends StatelessWidget {
  static String route = "/noticeView";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => NoticeViewWidget()
    }, home: NoticeViewWidget());
  }
}

class NoticeViewWidget extends StatefulWidget {
  @override
  NoticeViewState createState() => NoticeViewState();
}

class NoticeViewState extends State<NoticeViewWidget> {
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Screen.keepOn(true);
    return Scaffold(
        appBar: AppBar(title: Text(StringClass.NOTICE)),
        body: Center(
            child: Container(
          child: StreamBuilder<QuerySnapshot>(
            stream:
            FirebaseFirestore.instance.collection(COLLECTION_NOTICE).orderBy(FIELD_TIME,descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<NoticeData> list = new List();
                DATABASE.noticeDao.deleteAll();
                for (int i = 0; i < snapshot.data.docs.length; i++) {
                  DocumentSnapshot ds = snapshot.data.docs[i];
                  String title = ds[FIELD_TITLE];
                  String content = ds[FIELD_CONTENT];
                  String image = ds[FIELD_IMAGE];
                  NoticeData data =
                      new NoticeData(ds.id, title, content, image);
                  print("data $data");
                  list.add(data);
                }
                DATABASE.noticeDao.insertAll(list);
                return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildRow(list[index]);
                    });
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

  Widget buildRow(NoticeData data) {
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  NoticeDetailViewWidget(data.docu),
            ),
          );
        },
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 2 / 4,
                        child: Text(
                          data.title,
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        )),
                    Container(
                        width: MediaQuery.of(context).size.width * 1 / 4,
                        child: Text(
                          getDateText(int.parse(data.docu)),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        )),
                  ],
                ))));
  }
}
