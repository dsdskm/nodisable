import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screen/screen.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/cahced.dart';
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
  Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    var imgSize = MediaQuery
        .of(context)
        .size
        .width / 1.5;
    var fontSize = 40;
    if (MediaQuery
        .of(context)
        .orientation == Orientation.landscape) {
      imgSize = MediaQuery
          .of(context)
          .size
          .height / 1.5;
      fontSize = 25;
    }
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
                          width: imgSize,
                          height: imgSize,
                        ),
                        AutoSizeText(
                          StringClass.LABEL,
                          style:
                          TextStyle(fontSize: getFont(fontSize, context)),
                          maxLines: 1,
                        ),
                      ],
                    )))));
  }

  syncCategory() {
    print("syncCategory");
    FirebaseFirestore.instance
        .collection(COLLECTION_CATEGORY)
        .snapshots()
        .listen((event) {
      List<CategoryData> list = new List();
      List<CategoryData> depth1_list = new List();
      DATABASE.categoryDao.deleteAll();
      for (int i = 0; i < event.docs.length; i++) {
        DocumentSnapshot ds = event.docs[i];
        List<dynamic> menu = ds[FIELD_MENU_CATEGORY];

        CategoryData cd = CategoryData(0, 0, FIELD_MENU_CATEGORY, "전체");
        list.add(cd);
        depth1_list.add(cd);
        for (int i = 0; i < menu.length; i++) {
          String category = menu[i];
          print("category $category");
          CategoryData cd =
          CategoryData(i + 1, 0, FIELD_MENU_CATEGORY, category);
          list.add(cd);
          depth1_list.add(cd);
        }

        for (int j = 0; j < depth1_list.length; j++) {
          CategoryData sub_cd = depth1_list[j];
          print("sub_cd $sub_cd");
          if (sub_cd.value == "전체") {
            CategoryData data = CategoryData(0, 1, sub_cd.value, "전체");
            list.add(data);
            continue;
          }
          List<dynamic> subMenu = ds[sub_cd.value];
          for (int k = 0; k < subMenu.length; k++) {
            String sub_category = subMenu[k];
            print("sub_category $sub_category");
            CategoryData data = CategoryData(k, 1, sub_cd.value, sub_category);
            list.add(data);
          }
        }
      }
      DATABASE.categoryDao.insertAll(list);
      CATEGORY_LIST = list;
      Navigator.popAndPushNamed(context, MainView.route);
    });
  }

  syncData() {
    print("syncData");
    FirebaseFirestore.instance
        .collection(COLLECTION_LOCATION)
        .snapshots()
        .listen((event) {
      List<PlaceData> list = new List();
      DATABASE.placeDao.deleteAll();
      for (int i = 0; i < event.docs.length; i++) {
        Map<String, dynamic> ds = event.docs[i].data();
        String id = event.docs[i].id;
        print("id ${id}");
        String address = nullCheck(ds[FIELD_ADDRESS]);
        String category1 = nullCheck(ds[FIELD_CATEGORY1]);
        String category2 = nullCheck(ds[FIELD_CATEGORY2]);
        String contact = nullCheck(ds[FIELD_CONTACT]);
        bool elevator = ds[FIELD_ELEVATOR];
        String floor = nullCheck(ds[FIELD_FLOOR].toString());
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
        Map<dynamic, dynamic> images = ds[FIELD_IMAGES];
        List<dynamic> json_image_elevator = images[FIELD_IMAGE_ELEVATOR];
        List<dynamic> json_image_gyungsaro = images[FIELD_IMAGE_GYUNGSARO];
        List<dynamic> json_image_parking = images[FIELD_IMAGE_PARKING];
        List<dynamic> json_image_restroom = images[FIELD_IMAGE_RESTROOM];

        String str_images_elevator = "";
        for (int i = 0; i < json_image_elevator.length; i++) {
          str_images_elevator += json_image_elevator[i];
          if (i != json_image_elevator.length - 1) {
            str_images_elevator += ",";
          }
        }
        String str_image_gyungsaro = "";
        for (int i = 0; i < json_image_gyungsaro.length; i++) {
          str_image_gyungsaro += json_image_gyungsaro[i];
          if (i != json_image_gyungsaro.length - 1) {
            str_image_gyungsaro += ",";
          }
        }

        String str_image_parking = "";
        for (int i = 0; i < json_image_parking.length; i++) {
          str_image_parking += json_image_parking[i];
          if (i != json_image_parking.length - 1) {
            str_image_parking += ",";
          }
        }

        String str_image_restroom = "";
        for (int i = 0; i < json_image_restroom.length; i++) {
          str_image_restroom += json_image_restroom[i];
          if (i != json_image_restroom.length - 1) {
            str_image_restroom += ",";
          }
        }

        PlaceData pd = PlaceData(
            id,
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
            image_restroom,
            str_images_elevator,
            str_image_gyungsaro,
            str_image_parking,
            str_image_restroom);
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
