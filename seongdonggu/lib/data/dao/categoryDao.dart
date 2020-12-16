import 'package:floor/floor.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';

@dao
abstract class CategoryDao {
  @Query('SELECT * FROM categoryTable')
  Future<List<CategoryData>> getAllCategory();

  @insert
  Future<void> insertData(CategoryData data);

  @insert
  Future<void> insertAll(List<CategoryData> data);

  @Query('DELETE FROM categoryTable')
  Future<void> deleteAll();
}
