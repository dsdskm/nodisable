import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:seongdonggu/data/database.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/naviData.dart';

MyDatabase DATABASE;
double SIZE_WIDTH = 0;
double SIZE_HEIGHT = 0;
double RATIO = 0;
double PADDING_TOP = 0;
double TOP_BAR_HEIGHT = 60;

setSize(MediaQueryData m) {
  SIZE_HEIGHT = m.size.height; //앱 화면 높이 double Ex> 692.0
  SIZE_WIDTH = m.size.width; //앱 화면 넓이 double Ex> 360.0
  RATIO = m.devicePixelRatio; //화면 배율    double Ex> 4.0
  PADDING_TOP = m.padding.top; //상단 상태 표시줄 높이 double Ex> 24.0
  print(
      "setSize width : $SIZE_WIDTH, height : $SIZE_HEIGHT, ratio : $RATIO, padding top : $PADDING_TOP");
}

List<CategoryData> CATEGORY_LIST = new List();
List<NaviData> NAVI_LIST = new List();

List<Position> FAKE_POST_LIST = [
  Position(latitude: 37.547981, longitude: 126.822801),
  Position(latitude: 37.548014, longitude: 126.822776),
  Position(latitude: 37.548038, longitude: 126.822766),
  Position(latitude: 37.548061, longitude: 126.822766),
  Position(latitude: 37.548077, longitude: 126.822787),
  Position(latitude: 37.548086, longitude: 126.822825),
  Position(latitude: 37.548093, longitude: 126.822870),
  Position(latitude: 37.548105, longitude: 126.822919),
  Position(latitude: 37.548120, longitude: 126.822978),
  Position(latitude: 37.548137, longitude: 126.823033),
  Position(latitude: 37.548151, longitude: 126.823089),
  Position(latitude: 37.548166, longitude: 126.823124),
  Position(latitude: 37.548198, longitude: 126.823179),
  Position(latitude: 37.548213, longitude: 126.823234),
  Position(latitude: 37.548254, longitude: 126.823294),
  Position(latitude: 37.548285, longitude: 126.823334),
  Position(latitude: 37.548319, longitude: 126.823336),
  Position(latitude: 37.548342, longitude: 126.823311),
  Position(latitude: 37.548362, longitude: 126.823287),
  Position(latitude: 37.548395, longitude: 126.823264),
  Position(latitude: 37.548420, longitude: 126.823237),
  Position(latitude: 37.548444, longitude: 126.823219),
  Position(latitude: 37.548469, longitude: 126.823195),
];
List<Position> FAKE_POST_LIST2 = [
  Position(latitude: 37.547988, longitude: 126.822802),
  Position(latitude: 37.548069, longitude: 126.822838),
  Position(latitude: 37.548081, longitude: 126.822768),
  Position(latitude: 37.548060, longitude: 126.822671),
  Position(latitude: 37.548040, longitude: 126.822628),
  Position(latitude: 37.548038, longitude: 126.822574),
];

int fake_index = 0;

getFakePosition() {
  if (fake_index < FAKE_POST_LIST.length - 1) {
    fake_index++;
  }
  return FAKE_POST_LIST[fake_index];
  // if(fake_index==FAKE_POST_LIST.length){
  //   fake_index = 0;
  // }
  // return FAKE_POST_LIST[fake_index];
}

