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
  getPos(37.548022, 126.822496),
  getPos(37.54805601129031, 126.82252464232351),
  getPos(37.54805246188759, 126.82256717198689),
  getPos(37.548048912484695, 126.82262760887696),
  getPos(37.548073758301406, 126.82264999291029),
  getPos(37.548061335394095, 126.8226835689603),
  getPos(37.54806311009526, 126.82271042980034),
  getPos(37.54806843419854, 126.8227260986237),
  getPos(37.54807198360049, 126.82275519786705),
  getPos(37.54807198360049, 126.82277982030375),
  getPos(37.548079082403916, 126.82280891954711),
  getPos(37.54808440650604, 126.82284249559716),
  getPos(37.54809505470913, 126.82289397887386),
  getPos(37.54809860410984, 126.82295441576392),
  getPos(37.54810037881012, 126.8229835150073),
  getPos(37.54808263180536, 126.823034998284),
  getPos(37.54805956069288, 126.82310662719075),
  getPos(37.5480648847964, 126.82315363366078),
  getPos(37.54804358838005, 126.8232051169375),
  getPos(37.548022291957615, 126.82327226903756),
  getPos(37.54802406665972, 126.82331479870095),
  getPos(37.54801519314877, 126.82336180517098),
  getPos(37.54800277023169, 126.8234311956744),
];

getPos(double d, double e) {
  return Position(latitude: d, longitude: e);
}

int fake_index = 0;

getFakePosition() {
  if (fake_index < FAKE_POST_LIST2.length - 1) {
    fake_index++;
  }
  print("getFakePosition ${FAKE_POST_LIST2[fake_index]}");
  return FAKE_POST_LIST2[fake_index];
}
