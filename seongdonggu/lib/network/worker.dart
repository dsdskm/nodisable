import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:naver_map_plugin/naver_map_plugin.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/data/dto/naviData.dart';
import 'package:seongdonggu/data/dto/searchResultData.dart';

final GOOGLE_API_KEY = "AIzaSyC6F789FbCBc50kX1V1hdOaxFUufECWErg";
var DIRECTION_URL = "https://maps.googleapis.com/maps/api/directions/json?";
Future<List<PathOverlay>> requestDirection(var start_lat, var start_lon,
    var destination_lat, var destination_lon) async {
  print(
      "requestDirection3 from $start_lat ,$start_lon to $destination_lat,$destination_lon");
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
  for (int i = 0; i < features.length; i++) {
    dynamic data = features[i];
    dynamic geometry = data['geometry'] as Map<String, dynamic>;
    String type = geometry['type'];
    List<List<dynamic>> coordinates = new List<List<dynamic>>();
    if (type == "Point") {
      List<dynamic> tmp = geometry['coordinates'] as List<dynamic>;
      coordinates.add(tmp);
    } else if (type == "LineString") {
      var tmp = geometry['coordinates'] as List<dynamic>;
      for (int j = 0; j < tmp.length; j++) {
        List<dynamic> sub_tmp = tmp[j] as List<dynamic>;
        coordinates.add(sub_tmp);
      }
      // coordinates = geometry['coordinates'] as List<dynamic>;
    }

    dynamic properties = data['properties'] as Map<String, dynamic>;
    int index = properties['index'];
    int pointIndex = properties['pointIndex'];
    String name = properties['name'];
    String guidePointName = properties['guidePointName'];
    String description = properties['description'];
    int turnType = properties['turnType'];
    String pointType = properties['pointType'];

    NaviData nav = new NaviData(type, coordinates, index, pointIndex, name,
        guidePointName, description, turnType, pointType);
    list.add(nav);
    print("nav $nav");
    for (int j = 0; j < coordinates.length; j++) {
      LatLng latlng = new LatLng(coordinates[j][1], coordinates[j][0]);
      latlngList.add(latlng);
    }
  }
  PathOverlay po = PathOverlay(PathOverlayId("1"), latlngList);
  NAVI_LIST = list;
  print("requestDirection latlngList $latlngList");
  List<PathOverlay> ret = List<PathOverlay>();
  ret.add(po);
  return ret;
}

Future getSearchResult(String query,double lat,double lon) async {
  String url = "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$query&coordinate=$lon,$lat";
  print("getSearchResult url $url");
  final response = await get(url,
  headers: {
    "X-NCP-APIGW-API-KEY-ID":"quld7x8r88",
    "X-NCP-APIGW-API-KEY":"nPoZMaMl5jUrER2NRzsGP0GiD5t7Ann4IC9mfFPT"
  });
  final responseJson = json.decode(response.body);
  print("getSearchResult $responseJson");
  List<SearchResultData> list = List();
  var meta = responseJson['meta'];
  var totalCount = meta['totalCount'];
  var address = responseJson["addresses"];
  print("getSearchResult totalCount $totalCount address $address");
  for (int i = 0; i < totalCount; i++) {
    if(i==5){
      break;
    }
    print(address[i]);
    var address1 = address[i]["roadAddress"];
    var address2 = address[i]["jibunAddress"];
    double latitude = double.parse(address[i]["y"]);
    double longitude = double.parse(address[i]["x"]);
    double distance = address[i]["distance"];
    list.add(
        SearchResultData(address1, address2, latitude, longitude, distance));
  }
  return list;
}

