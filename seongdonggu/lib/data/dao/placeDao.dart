import 'package:floor/floor.dart';
import 'package:seongdonggu/data/dto/placeData.dart';

@dao
abstract class PlaceDao {
  @Query('SELECT * FROM placeTable')
  Future<List<PlaceData>> getAllPlace();

  @insert
  Future<void> insertData(PlaceData data);

  @insert
  Future<void> insertAll(List<PlaceData> data);

  @Query('DELETE FROM placeTable')
  Future<void> deleteAll();
}
