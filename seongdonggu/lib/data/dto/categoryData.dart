import 'package:floor/floor.dart';

@Entity(tableName: 'categoryTable')
class CategoryData {
  @PrimaryKey(autoGenerate: true)
  int uid;
  int index;
  int depth;
  String category;
  String value;

  CategoryData(this.index, this.depth,this.category, this.value);

  @override
  String toString() {
    return 'CategoryData{uid: $uid, index: $index, depth: $depth, category: $category, value: $value}';
  }
}