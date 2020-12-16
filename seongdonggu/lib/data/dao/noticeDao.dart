import 'package:floor/floor.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';

@dao
abstract class NoticeDao {
  @Query('SELECT * FROM notice')
  Future<List<NoticeData>> getAllNotice();

  @Query('SELECT * FROM notice WHERE docu=:docu')
  Future<NoticeData> getNotice(String docu);

  @insert
  Future<void> insertAll(List<NoticeData> data);

  @Query('DELETE FROM notice')
  Future<void> deleteAll();
}
