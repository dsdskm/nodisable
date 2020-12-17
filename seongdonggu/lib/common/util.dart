import 'dart:ffi';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
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
