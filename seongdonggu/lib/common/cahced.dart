import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seongdonggu/data/database.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/naviData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';

MyDatabase DATABASE;
double SIZE_WIDTH = 0;
double SIZE_HEIGHT = 0;
double RATIO = 1;
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
List<PlaceData> PLACE_LIST = new List();
List<PlaceData> FILTERED_LIST = List();

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
  getPos(37.56277240352224, 127.0343228003643),
  getPos(37.56275217606487, 127.03432917976836),
  getPos(37.5627370054682, 127.0343467231295),
  getPos(37.56272309908523, 127.03436426649066),
  getPos(37.562709192699636, 127.03438499955382),
  getPos(37.562695286311474, 127.03440094806395),
  getPos(37.56268517257299, 127.03441530172307),
  getPos(37.56266368087414, 127.03443762963727),
  getPos(37.562638396514615, 127.03441211202104),
  getPos(37.562627018550046, 127.03439775836193),
  getPos(37.562609319490576, 127.0343802150008),
  getPos(37.56259794152156, 127.03435948193761),
  getPos(37.562581506674356, 127.03434193857646),
  getPos(37.56256633604293, 127.03432599006632),
  getPos(37.56254990118875, 127.03430844670518),
  getPos(37.56253725899077, 127.03428930849302),
  getPos(37.5625139210379, 127.03426780295848),
  getPos(37.562500390258656, 127.03424314705222),
  getPos(37.56247633553394, 127.03422607757867),
  getPos(37.56245378422248, 127.03420142167245),
  getPos(37.56243273632561, 127.03419193863158),
  getPos(37.56240266789123, 127.03417486915802),
  getPos(37.5623921439363, 127.03414073021092),
  getPos(37.56237710971243, 127.03409710822295),
  getPos(37.562347041255556, 127.03409900483113),
  getPos(37.562329000175644, 127.03407434892488),
  getPos(37.56231546935631, 127.03406107266734),
  getPos(37.56232298647486, 127.03398900155678),
  getPos(37.5623447861143, 127.03394253465655),
  getPos(37.562314717644426, 127.03391977535848),
  getPos(37.56229517313247, 127.03388753301952),
  getPos(37.5622786354645, 127.03384391103155),
  getPos(37.562251573818116, 127.03382684155804),
  getPos(37.56222902243862, 127.03379839243543),
  getPos(37.56219143679093, 127.03382304834166),
  getPos(37.56217339567331, 127.03384391103155),
  getPos(37.562153851124314, 127.03387046354601),
  getPos(37.56212678942974, 127.03385529067899),
  getPos(37.56210123115632, 127.03383063477276),
  getPos(37.562081686588364, 127.0338135652992),
  getPos(37.56205161801228, 127.03378511617663),
  getPos(37.56202906657225, 127.03376046027037),
  getPos(37.56200350826532, 127.03373390775597),
  getPos(37.56197494308833, 127.03370735524156),
  getPos(37.56194487446916, 127.03368649255164),
  getPos(37.56192833672344, 127.03365045699638),
  getPos(37.561904281814044, 127.03362390448197),
  getPos(37.56187722003166, 127.03360304179206),
  getPos(37.561854668538835, 127.03357838588583),
  getPos(37.56182760673139, 127.03358407571088),
  getPos(37.561802048355325, 127.03360114518442),
  getPos(37.56178551057792, 127.03364097395605),
  getPos(37.56177047623161, 127.03366752647045),
  getPos(37.561753938447204, 127.03369028576853),
  getPos(37.561737400659084, 127.0337263213238),
  getPos(37.561719359431514, 127.03374908062186),
  getPos(37.56170658022603, 127.03377089161587),
  getPos(37.56169304930016, 127.03379175430575),
  getPos(37.561670497751585, 127.0338239966447),
  getPos(37.56165395994497, 127.03384675594276),
  getPos(37.56163140838456, 127.03388848132253),
  getPos(37.5616043465031, 127.03391503383698),
  getPos(37.5615607467828, 127.0339302067024),
  getPos(37.56153518831519, 127.03396434564951),
  getPos(37.56151263671883, 127.03398900155575),
];

getPos(double d, double e) {
  return Position(latitude: d, longitude: e);
}

int fake_index = 0;

resetFakePosition() {
  fake_index = 0;
}

getFakePosition() {
  if (fake_index < FAKE_POST_LIST2.length - 1) {
    fake_index++;
  }
  print(
      "getFakePosition fake_index $fake_index , ${FAKE_POST_LIST2[fake_index]}");
  return FAKE_POST_LIST2[fake_index];
}

getFont(int value, BuildContext context) {
  var fontSize = MediaQuery.of(context).textScaleFactor;
  double ret = value.toDouble();

  if (fontSize <= 1) {
    ret = ret * 2;
  }

  if(RATIO>=3){
    ret = ret / 2;
  }
  print("getFont value $value fontSize $fontSize ret $ret RATIO $RATIO");
  return ret;
}
