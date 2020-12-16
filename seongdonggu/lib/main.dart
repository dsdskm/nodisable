import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seongdonggu/commentView.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/test.dart';
import 'package:seongdonggu/common/util.dart';
import 'package:seongdonggu/data/database.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';
import 'package:seongdonggu/googleView.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DATABASE = await $FloorMyDatabase.databaseBuilder('my_database.db').build();
  runApp(MyApp());
  test();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //checkNetworkConnection(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: <String, WidgetBuilder>{
        MainView.route: (BuildContext context) => new MainViewWidget(),
        // MapView.route: (BuildContext context) => new MapViewWidget(),
        CommentView.route: (BuildContext context) => new CommentViewWidget(),
      },
      home: MyHomePage(),
    );
  }
}

void checkNetworkConnection(BuildContext context) async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    print("Network type is mobile");
  } else if (connectivityResult == ConnectivityResult.wifi) {
    print("Network type is wifi");
  } else {
    print("Network type is unknown");
    Fluttertoast.showToast(
        msg: "네트워크 상태를 확인 후 재실행 해주세요.",
        backgroundColor: Colors.lightBlue,
        gravity: ToastGravity.CENTER);
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    // showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //           title: new Text("네트워크 오류"),
    //           content: new Text("네트워크 상태를 확인하세요"),
    //           actions: <Widget>[
    //             new FlatButton(
    //               child: new Text("확인"),
    //               onPressed: () {
    //                 SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    //               },
    //             ),
    //           ],
    //         ));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;

  @override
  void initState() {
    print("initState");
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      syncData();
      _timer.cancel();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    setSize(MediaQuery.of(context));
    return Scaffold(
        body: Center(
            child: GestureDetector(
                onTap: () {
                  print("onTap");
                },
                child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("asset/images/logo.png",width: 300,height: 300,),
                        Text(StringClass.LABEL, style: TextStyle(fontSize: 50)),
                      ],
                    )))));
  }

  syncCategory() {
    print("syncCategory");
    Firestore.instance
        .collection(COLLECTION_CATEGORY)
        .snapshots()
        .listen((event) {
      List<CategoryData> list = new List();
      List<CategoryData> depth1_list = new List();
      DATABASE.categoryDao.deleteAll();
      // length =1;

      for (int i = 0; i < event.documents.length; i++) {
        DocumentSnapshot ds = event.documents[i];
        List<dynamic> menu = ds[FIELD_MENU_CATEGORY];
        for (int i = 0; i < menu.length; i++) {
          String category = menu[i];
          CategoryData cd = CategoryData(i, 0, FIELD_MENU_CATEGORY, category);
          list.add(cd);
          depth1_list.add(cd);
        }
        print("syncCategory list $list");
        for (int j = 0; j < depth1_list.length; j++) {
          CategoryData sub_cd = depth1_list[j];
          print("sub_cd $sub_cd");
          List<dynamic> subMenu = ds[sub_cd.value];
          for (int k = 0; k < subMenu.length; k++) {
            String sub_category = subMenu[k];
            CategoryData data = CategoryData(k, 1, sub_cd.value, sub_category);
            list.add(data);
          }
        }
      }
      print("syncCategory ${list.length}");
      print("syncCategory $list");
      DATABASE.categoryDao.insertAll(list);
      CATEGORY_LIST = list;
      // Navigator.popAndPushNamed(context, MapView.route);
      Navigator.popAndPushNamed(context, MainView.route);
    });
  }

  syncData() {
    print("syncData");

    Firestore.instance
        .collection(COLLECTION_LOCATION)
        .snapshots()
        .listen((event) {
      List<PlaceData> list = new List();
      DATABASE.placeDao.deleteAll();
      for (int i = 0; i < event.documents.length; i++) {
        DocumentSnapshot ds = event.documents[i];
        String address = ds[FIELD_ADDRESS];
        String category1 = ds[FIELD_CATEGORY1];
        String category2 = ds[FIELD_CATEGORY2];
        String contact = ds[FIELD_CONTACT];
        bool elevator = ds[FIELD_ELEVATOR];
        String floor = ds[FIELD_FLOOR];
        bool gyungsaro = ds[FIELD_GYUNGSARO];
        double latitude = ds[FIELD_LATITUDE];
        double longitude = ds[FIELD_LONGITUDE];
        String name = ds[FIELD_NAME];
        bool parking = ds[FIELD_PARKING];
        bool restroom = ds[FIELD_RESTROOM];
        String summary = ds[FIELD_SUMMARY];
        bool using = ds[FIELD_USING];
        Map<dynamic, dynamic> image = ds[FIELD_IMAGE];
        String image_base = image[FIELD_IMAGE_BASE];
        String image_elevator = image[FIELD_IMAGE_ELEVATOR];
        String image_gyungsaro = image[FIELD_IMAGE_GYUNGSARO];
        String image_parking = image[FIELD_IMAGE_PARKING];
        String image_restroom = image[FIELD_IMAGE_RESTROOM];
        PlaceData pd = PlaceData(
            ds.documentID,
            address,
            category1,
            category2,
            contact,
            elevator,
            floor,
            gyungsaro,
            latitude,
            longitude,
            name,
            parking,
            restroom,
            summary,
            using,
            image_base,
            image_elevator,
            image_gyungsaro,
            image_parking,
            image_restroom);
        if (pd.using == null || pd.using) {
          list.add(pd);
        }
      }
      DATABASE.placeDao.insertAll(list);
      print("sync list size ${list.length}");
      syncCategory();
    });
  }
}
