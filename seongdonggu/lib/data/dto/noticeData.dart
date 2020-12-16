

import 'package:floor/floor.dart';

@Entity(tableName:'notice')
class NoticeData{
  @PrimaryKey(autoGenerate: true)
  int uid;
  String docu;
  String title;
  String content;
  String image;

  NoticeData(this.docu, this.title, this.content, this.image);

  @override
  String toString() {
    return 'NoticeData{uid: $uid, docu: $docu, title: $title, content: $content, image: $image}';
  }
}