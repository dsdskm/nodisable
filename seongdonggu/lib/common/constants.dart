import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final DEBUG = false;

final NAVER_CLIENT_ID = "quld7x8r88";

final COLLECTION_LOCATION = "location";
final COLLECTION_CATEGORY = "category";
final COLLECTION_NOTICE = "notice";
final COLLECTION_COMMENT = "comment";
final COLLECTION_VERSION = "version";
final FIELD_ADDRESS = "address";
final FIELD_CATEGORY1 = "category1";
final FIELD_CATEGORY2 = "category2";
final FIELD_CONTACT = "contact";
final FIELD_ELEVATOR = "elevator";
final FIELD_FLOOR = "floor";
final FIELD_GYUNGSARO = "gyungsaro";
final FIELD_LATITUDE = "latitude";
final FIELD_LONGITUDE = "longitude";
final FIELD_NAME = "name";
final FIELD_PARKING = "parking";
final FIELD_RESTROOM = "restroom";
final FIELD_SUMMARY = "summary";
final FIELD_USING = "using";
final FIELD_IMAGE = "image";
final FIELD_IMAGE_BASE = "base";
final FIELD_IMAGE_ELEVATOR = "elevator";
final FIELD_IMAGE_GYUNGSARO = "gyungsaro";
final FIELD_IMAGE_PARKING = "parking";
final FIELD_IMAGE_RESTROOM = "restroom";
final FIELD_MENU_CATEGORY = "카테고리";
final FIELD_MENU_FOOD = "음식";
final FIELD_MENU_ETC = "기타";
final FIELD_TITLE = "title";
final FIELD_TIME = "time";
final FIELD_TEXT = "text";
final FIELD_CONTENT = "content";

var CURRENT_LOCATION_CHECK_DELAY = 15;
final NAVI_LIST_DISTANCE = 10;
final NAVI_LIMIT_DISTANCE_MAX = 1000;
final NAVI_LIMIT_DISTANCE_MIN = 50;
final RELEASE = "release_1.0";
final NAVI_DETAIL_BOTTOM_HEIGHT = 100.0;
final NAVI_DETAIL_RIGHT_WIDTH = 180.0;
final RADIUS = ["100m", "200m", "300m", "400m", "500m"];
enum TtsState { playing, stopped }

BoxDecoration BOX_DECORATION = new BoxDecoration(
    border: new Border.all(width: 1, color: Colors.transparent),
//color is transparent so that it does not blend with the actual color specified
    borderRadius: const BorderRadius.all(const Radius.circular(30.0)),
    color: new Color.fromRGBO(0, 0, 0, 0.1));
