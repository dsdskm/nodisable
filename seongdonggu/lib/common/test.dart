import 'package:cloud_firestore/cloud_firestore.dart';

test(){
  addNoticeText();
}

addNoticeText(){
  print("addNoticeText");
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항1', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항2', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항3', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항긴제목테스트입니다1공지사항긴제목테스트입니다1', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항3', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항4', "content": "내용", "image":"http://dsdskm.com/nodisable/seongdonggu/image4.jpg"});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항5', "content": "내용", "image":""});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항6', "content": "내용", "image":""});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항7', "content": "내용", "image":""});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항8', "content": "내용", "image":""});
  Firestore.instance.collection('notice').document(DateTime.now().millisecondsSinceEpoch.toString())
      .setData({ 'title': '공지사항9', "content": "내용", "image":""});
}