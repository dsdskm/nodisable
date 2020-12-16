import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/data/dto/naviData.dart';

final GOOGLE_API_KEY = "AIzaSyC6F789FbCBc50kX1V1hdOaxFUufECWErg";
var DIRECTION_URL = "https://maps.googleapis.com/maps/api/directions/json?";

// Future<Response> requestDirection(var start_lat, var start_lon,
//     var destination_lat, var destination_lon) async {
//   // sample https://maps.googleapis.com/maps/api/directions/json?origin=37.5728359,126.9746922&destination=37.5129907,127.1005382&mode=transit&departure_time=now&key=당신의 API Key
//   // mode = driving, walking, bicycling, transit
//   var mode = "&mode=walking";
//   var departure_time = "&departure_time=now";
//   var url =
//       "$DIRECTION_URL${mode}&origin=${start_lat},${start_lon}&destination=${destination_lat},${destination_lon}${mode}${departure_time}&key=$GOOGLE_API_KEY";
//   print("url $url");
//
//   final response = await get(url);
//   print("result ${response.statusCode}");
//   print("result ${response.body}");
// }
//
// Future<List<PathOverlay>> requestDirection2(var start_lat, var start_lon,
//     var destination_lat, var destination_lon) async {
//   print("requestDirection2 from $start_lat ,$start_lon to $destination_lat,$destination_lon");
//   var url =
//       "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json&startX=$start_lon&startY=$start_lat&endX=$destination_lon&endY=$destination_lat&startName=START&endName=DESTI&appKey=l7xxf6b542e948174f9298ab3a049d7a5d37";
//   print("requestDirection2 $url");
//   final response = await get(url);
//   print("result ${response.statusCode}");
//   print("result ${response.body}");
//   String body = response.body;
//   Map<String, dynamic> content = json.decode(body);
//   var features = content['features'] as List<dynamic>;
//   List<NaviData> list = new List();
//   List<LatLng> latlngList = new List();
//   for(int i=0;i<features.length;i++){
//     dynamic data = features[i];
//     dynamic geometry = data['geometry'] as Map<String,dynamic>;
//     String type = geometry['type'];
//     List<List<dynamic>>   coordinates = new List<List<dynamic>>();
//     if(type=="Point"){
//       List<dynamic> tmp = geometry['coordinates'] as List<dynamic>;
//       coordinates.add(tmp);
//     } else if(type=="LineString"){
//       var tmp = geometry['coordinates'] as List<dynamic>;
//       for(int j=0;j<tmp.length;j++){
//         List<dynamic> sub_tmp = tmp[j] as List<dynamic>;
//         coordinates.add(sub_tmp);
//       }
//       // coordinates = geometry['coordinates'] as List<dynamic>;
//     }
//
//     dynamic properties = data['properties'] as Map<String,dynamic>;
//     int index = properties['index'];
//     int pointIndex = properties['pointIndex'];
//     String name = properties['name'];
//     String guidePointName = properties['guidePointName'];
//     String description = properties['description'];
//     int turnType = properties['turnType'];
//     String pointType = properties['pointType'];
//
//     NaviData nav = new NaviData(coordinates, index, pointIndex, name,
//         guidePointName, description, turnType, pointType);
//     list.add(nav);
//
//
//     for(int j=0;j<coordinates.length;j++){
//       print("kkh coordinates[j] ${coordinates[j][0]}");
//       LatLng latlng = new LatLng(coordinates[j][1],coordinates[j][0]);
//       latlngList.add(latlng);
//     }
//   }
//   List<PathOverlay> overlays = [PathOverlay(PathOverlayId("1"), latlngList)];
//   print("kkh latlngList $latlngList overlays $overlays");
//   return overlays;
//
// }
Future<List<Polyline>> requestDirection3(var start_lat, var start_lon,
    var destination_lat, var destination_lon) async {
  print("requestDirection3 from $start_lat ,$start_lon to $destination_lat,$destination_lon");
  var url =
      "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json&startX=$start_lon&startY=$start_lat&endX=$destination_lon&endY=$destination_lat&startName=START&endName=DESTI&appKey=l7xxf6b542e948174f9298ab3a049d7a5d37";
  print("requestDirection2 $url");
  final response = await get(url);
  print("result ${response.statusCode}");
  print("result ${response.body}");
  String body = response.body;
  Map<String, dynamic> content = json.decode(body);
  var features = content['features'] as List<dynamic>;
  List<NaviData> list = new List();
  List<LatLng> latlngList = new List();
  for(int i=0;i<features.length;i++){
    dynamic data = features[i];
    dynamic geometry = data['geometry'] as Map<String,dynamic>;
    String type = geometry['type'];
    List<List<dynamic>>   coordinates = new List<List<dynamic>>();
    if(type=="Point"){
      List<dynamic> tmp = geometry['coordinates'] as List<dynamic>;
      coordinates.add(tmp);
    } else if(type=="LineString"){
      var tmp = geometry['coordinates'] as List<dynamic>;
      for(int j=0;j<tmp.length;j++){
        List<dynamic> sub_tmp = tmp[j] as List<dynamic>;
        coordinates.add(sub_tmp);
      }
      // coordinates = geometry['coordinates'] as List<dynamic>;
    }

    dynamic properties = data['properties'] as Map<String,dynamic>;
    int index = properties['index'];
    int pointIndex = properties['pointIndex'];
    String name = properties['name'];
    String guidePointName = properties['guidePointName'];
    String description = properties['description'];
    int turnType = properties['turnType'];
    String pointType = properties['pointType'];

    NaviData nav = new NaviData(coordinates, index, pointIndex, name,
        guidePointName, description, turnType, pointType);
    list.add(nav);
    print("nav $nav");
    for(int j=0;j<coordinates.length;j++){
      LatLng latlng = new LatLng(coordinates[j][1],coordinates[j][0]);
      latlngList.add(latlng);
    }
  }
  List<Polyline> overlays = <Polyline>[
    Polyline(
        polylineId: PolylineId("1"),
        visible: true,
        points: latlngList,
        color: Colors.blue)
  ];
  NAVI_LIST = list;
  print("requestDirection3 latlngList $latlngList");
  print("requestDirection3 overlays ${overlays.length}");
  return overlays;
}
