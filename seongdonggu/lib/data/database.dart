import 'dart:async';
import 'package:floor/floor.dart';
import 'package:seongdonggu/data/dao/categoryDao.dart';
import 'package:seongdonggu/data/dao/noticeDao.dart';
import 'package:seongdonggu/data/dao/placeDao.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart';

/*
   flutter pub run build_runner build --delete-conflicting-outputs
   adb shell pm clear com.kkh.seongdonggu
   flutter clean
   flutter build apk --release
   flutter build appbundle
    */
@Database(version: 1, entities: [PlaceData,NoticeData,CategoryData])
abstract class MyDatabase extends FloorDatabase {
  PlaceDao get placeDao;
  NoticeDao get noticeDao;
  CategoryDao get categoryDao;
}
