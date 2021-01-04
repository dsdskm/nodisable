import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:launch_review/launch_review.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';

showToast(String msg) async {
  Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.lightBlue,
      gravity: ToastGravity.CENTER);
}

getDateText(int time) {
  print("time : $time , date : ${DateTime.now().millisecondsSinceEpoch}");
  DateFormat format = DateFormat("yyyy-MM-dd HH:mm");
  return format.format(new DateTime.fromMillisecondsSinceEpoch(time));
}

String nullCheck(String text) {
  return text != null ? text : "";
}

String nullImageCheck(String text, String image_base) {
  return text != null ? text : image_base;
}

// remoteconfig() async {
//   print("remoteconfig");
//   RemoteConfig _remoteConfig = await RemoteConfig.instance;
//   await _remoteConfig.fetch(expiration: const Duration(hours: 0));
//   await _remoteConfig.activateFetched();
//   print("remoteconfig hello : ${_remoteConfig.getString("hello")}");
// }

appVersionCheck(BuildContext context) {
  Firestore.instance
      .collection(COLLECTION_VERSION)
      .document(RELEASE)
      .get()
      .then((DocumentSnapshot ds) async {
    int android = ds.data["android"];
    int ios = ds.data["ios"];
    print("android $android ios $ios");
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String buildNumber = packageInfo.buildNumber;
    String version = packageInfo.buildNumber;
    print(
        "appName $appName packageName $packageName buildNumber $buildNumber version $version");
    if (Platform.isAndroid) {
      if (int.parse(version) < android) {
        showDownloadIDialog(context);
      }
    } else {
      if (int.parse(version) < ios) {
        showDownloadIDialog(context);
      }
    }
  });
}

showDownloadIDialog(BuildContext context) {
  print("showDownloadIDialog");
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: new Text(StringClass.UPDATE_TITLE),
            content: new Text(StringClass.UPDATE_MESSAGE),
            actions: <Widget>[
              new FlatButton(
                child: new Text(StringClass.GO_UPDATE),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop('dialog');
                  LaunchReview.launch(
                      androidAppId: "com.kkh.seongdonggu",
                      iOSAppId: "com.kkh.seongdonggu");
                },
              ),
            ],
          ));
}

getTurnTypeText(int turnType) {
  var retStr = "";
  switch (turnType) {
    case 11:
      retStr = "직진";
      break;
    case 12:
      retStr = "좌회전";
      break;
    case 13:
      retStr = "우회전";
      break;
    case 14:
      retStr = "유턴";
      break;
    case 16:
      retStr = "8시 방향 좌회전";
      break;
    case 17:
      retStr = "10시 방향 좌회전";
      break;
    case 18:
      retStr = "2시 방향 우회전";
      break;
    case 19:
      retStr = "4시 방향 우회전";
      break;
    case 125:
      retStr = "육교";
      break;
    case 126:
      retStr = "지하보도";
      break;
    case 127:
      retStr = "계단 진입";
      break;
    case 128:
      retStr = "경사로 진입";
      break;
    case 129:
      retStr = "계단 경사로 진입";
      break;
    case 211:
      retStr = "횡단보도";
      break;
    case 212:
      retStr = "촤즉 횡단보도";
      break;
    case 213:
      retStr = "우측 횡단보도";
      break;
    case 214:
      retStr = "8시 방향 횡단보도";
      break;
    case 215:
      retStr = "10시 방향 횡단보도";
      break;
    case 216:
      retStr = "2시 방향 횡단보도";
      break;
    case 217:
      retStr = "4시 방향 횡단보도";
      break;
  }
  return retStr + " ";
}
double calculateDistance(lat1, lon1, lat2, lon2){
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 +
      c(lat1 * p) * c(lat2 * p) *
          (1 - c((lon2 - lon1) * p))/2;
  return 12742 * asin(sqrt(a));
}

double totalDistance = calculateDistance(26.196435, 78.197535,26.197195, 78.196408);
