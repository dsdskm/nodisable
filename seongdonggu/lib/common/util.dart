import 'dart:ffi';
import 'dart:io';

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
