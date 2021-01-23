import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screen/screen.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/test.dart';
import 'package:seongdonggu/common/util.dart';
import 'package:seongdonggu/data/database.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';
import 'package:seongdonggu/mapView.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Screen.keepOn(true);
  DATABASE = await $FloorMyDatabase.databaseBuilder('my_database.db').build();
  runApp(MyApp());
  // if (Platform.isAndroid) {
  //   if (DEBUG) {
  //     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown]);
  //     test();
  //   } else {
  //     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  //   }
  // } else {
  //   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // }
  stderr.writeln('App start');
  developer.log('log me', name: 'App start');
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // setSize(MediaQuery.of(context));
    //checkNetworkConnection(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StringClass.LABEL,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: <String, WidgetBuilder>{
        MainView.route: (BuildContext context) => new MainViewWidget(),
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
        msg: StringClass.NETWORK_ERR_MSG,
        backgroundColor: Colors.lightBlue,
        gravity: ToastGravity.CENTER);
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
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
                        Image.asset(
                          "asset/images/logo.png",
                          width: 300,
                          height: 300,
                        ),
                        AutoSizeText(
                          StringClass.LABEL,
                          style: TextStyle(fontSize: getFont(40, context)),
                          
                          maxLines: 1,
                        ),
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
      for (int i = 0; i < event.documents.length; i++) {
        DocumentSnapshot ds = event.documents[i];
        List<dynamic> menu = ds[FIELD_MENU_CATEGORY];
        for (int i = 0; i < menu.length; i++) {
          String category = menu[i];
          CategoryData cd = CategoryData(i, 0, FIELD_MENU_CATEGORY, category);
          list.add(cd);
          depth1_list.add(cd);
        }
        for (int j = 0; j < depth1_list.length; j++) {
          CategoryData sub_cd = depth1_list[j];
          List<dynamic> subMenu = ds[sub_cd.value];
          for (int k = 0; k < subMenu.length; k++) {
            String sub_category = subMenu[k];
            CategoryData data = CategoryData(k, 1, sub_cd.value, sub_category);
            list.add(data);
          }
        }
      }
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
        String address = nullCheck(ds[FIELD_ADDRESS]);
        String category1 = nullCheck(ds[FIELD_CATEGORY1]);
        String category2 = nullCheck(ds[FIELD_CATEGORY2]);
        String contact = nullCheck(ds[FIELD_CONTACT]);
        bool elevator = ds[FIELD_ELEVATOR];
        String floor = nullCheck(ds[FIELD_FLOOR]);
        bool gyungsaro = ds[FIELD_GYUNGSARO];
        double latitude = ds[FIELD_LATITUDE];
        double longitude = ds[FIELD_LONGITUDE];
        String name = nullCheck(ds[FIELD_NAME]);
        bool parking = ds[FIELD_PARKING];
        bool restroom = ds[FIELD_RESTROOM];
        String summary = nullCheck(ds[FIELD_SUMMARY]);
        bool using = ds[FIELD_USING];
        Map<dynamic, dynamic> image = ds[FIELD_IMAGE];
        String image_base = "";
        String image_elevator = "";
        String image_gyungsaro = "";
        String image_parking = "";
        String image_restroom = "";
        if (image != null) {
          image_base = nullCheck(image[FIELD_IMAGE_BASE]);
          image_elevator =
              nullImageCheck(image[FIELD_IMAGE_ELEVATOR], image_base);
          image_gyungsaro =
              nullImageCheck(image[FIELD_IMAGE_GYUNGSARO], image_base);
          image_parking =
              nullImageCheck(image[FIELD_IMAGE_PARKING], image_base);
          image_restroom =
              nullImageCheck(image[FIELD_IMAGE_RESTROOM], image_base);
        }
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
      PLACE_LIST = list;
      DATABASE.placeDao.insertAll(list);
      syncCategory();
    });
  }
}
