import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

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
