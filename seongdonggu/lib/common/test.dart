import 'package:cloud_firestore/cloud_firestore.dart';

test() {
  // addNoticeText();
  // addData();
  // deleteTestData();
}

Future<void> deleteTestData() async {
  print("deleteTestData");
  QuerySnapshot qs =
      await Firestore.instance.collection('location').getDocuments();
  for (int i = 0; i < qs.documents.length; i++) {
    String docu = qs.documents[i].documentID;
    print("docu $docu");
    if (docu.startsWith("SportsFacilities")) {
      Firestore.instance.collection('location').document(docu).delete();
    }
  }
}

void addData() {
  print("addData");
  addLocation(
      "서울특별시 성동구 왕십리로 89(성수1가 685-697번지)",
      "체육시설",
      "체육시설",
      "02-2204-7620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.549770,
      126.824349,
      "성동구민종합체육센터(Test)",
      true);
  addLocation(
      "서울특별시 성동구 왕십리로 89(성수1가 685-697번지)",
      "체육시설",
      "체육시설",
      "02-2204-7620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.54603516892649,
      127.04416248447187,
      "성동구민종합체육센터",
      true);
  addLocation(
      "서울특별시 성동구 무수막길 69(금호2가 511번지)",
      "체육시설",
      "체육시설",
      "02-2204-7650",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55325455423112,
      127.01944646064521,
      "열린금호교육문화관",
      true);
  addLocation(
      "서울특별시 성동구 왕십리로 89(성수1가 685-697번지)",
      "체육시설",
      "체육시설",
      "02-2204-7640",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.56220254049174,
      127.04074764036491,
      "마장국민체육센터",
      true);
  addLocation(
      "서울특별시 천호대로 78길 15-48",
      "체육시설",
      "체육시설",
      "02-2204-6620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.56165462236375,
      127.05637994036496,
      "용답체육센터",
      true);
  addLocation(
      "서울특별시 성동구 금호로 20 금호스포츠센터",
      "체육시설",
      "체육시설",
      "02-2204-7675",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.54577207619905,
      127.02517093928951,
      "금호스포츠센터",
      true);
  addLocation(
      "서울특별시 성동구 독서당로63길 44(행당동 산 30-40)",
      "체육시설",
      "체육시설",
      "02-2204-7680",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55401263582175,
      127.03011118454243,
      "대현산공원체육관",
      true);
  addLocation(
      "서울특별시 성동구 장터1길 20(금호동3가 1266)",
      "체육시설",
      "체육시설",
      "02-2204-7690",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.54967990182718,
      127.0190367133779,
      "금호공원체육관",
      true);
  addLocation(
      "서울특별시 성동구 사근동 104(살곶이체육공원 내)",
      "체육시설",
      "체육시설",
      "02-2286-6090",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55393456400063,
      127.04835565755556,
      "살곶이야구장",
      true);
  addLocation(
      "서울특별시 성동구 사근동 104(살곶이체육공원 내)",
      "체육시설",
      "체육시설",
      "02-2204-7620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55393456400063,
      127.04835565755556,
      "살곶이물놀이장",
      true);
  addLocation(
      "서울 성동구 응봉동 235",
      "체육시설",
      "체육시설",
      "02-2204-7670",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.551264639743245,
      127.03669171337783,
      "응봉테니스장",
      true);
  addLocation(
      "서울 성동구 마조로15가길 23",
      "체육시설",
      "체육시설",
      "02-2282-7200",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.56448166803471,
      127.03989858269385,
      "마장테니스장",
      true);
  addLocation(
      "서울 성동구 응봉동 235",
      "체육시설",
      "체육시설",
      "02-2204-7650",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55117958058915,
      127.03654150968045,
      "응봉축구장",
      true);
  addLocation(
      "서울 성동구 응봉동 235",
      "체육시설",
      "체육시설",
      "02-2204-7650",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55117958058915,
      127.03654150968045,
      "응봉풋살장",
      true);
  addLocation(
      "서울 성동구 응봉동 235",
      "체육시설",
      "체육시설",
      "02-2204-7650",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55117958058915,
      127.03654150968045,
      "응봉족구장",
      true);
  addLocation(
      "성동구 독서당로60길 13-1",
      "체육시설",
      "체육시설",
      "02-2286-6061",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.548756979076835,
      127.03108912871984,
      "응봉산 암벽공원",
      true);
  addLocation(
      "서울 성동구 고산자로 260",
      "체육시설",
      "체육시설",
      "02-2296-4062",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.56319995726267,
      127.03679832872035,
      "성동청소년수련관",
      true);
  addLocation(
      "서울특별시 성동구 왕십리로 89(성수1가 685-697번지)",
      "체육시설",
      "체육시설",
      "02-2204-7620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.54603516892649,
      127.04416248447187,
      "성동구민종합체육센터",
      true);
  addLocation(
      "서울 성동구 동호로 21 옥수역 하부",
      "체육시설",
      "체육시설",
      "02-2204-7620",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.54603516892649,
      127.04416248447187,
      "옥수풋살장",
      true);
  addLocation(
      "서울 성동구 자동차시장3길 64 중랑물재생센터",
      "체육시설",
      "체육시설",
      "02-2211-2522",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55773538343783,
      127.0652238826939,
      "중랑물재생센터 족구장",
      true);
  addLocation(
      "서울 성동구 자동차시장3길 64 중랑물재생센터",
      "체육시설",
      "체육시설",
      "02-2211-2522",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55773538343783,
      127.0652238826939,
      "중랑물재생센터 축구장",
      true);
  addLocation(
      "서울 성동구 자동차시장3길 64 중랑물재생센터",
      "체육시설",
      "체육시설",
      "02-2211-2522",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55773538343783,
      127.0652238826939,
      "중랑물재생센터 테니스장",
      true);
  addLocation(
      "서울 성동구 자동차시장3길 64 중랑물재생센터",
      "체육시설",
      "체육시설",
      "02-2211-2522",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55773538343783,
      127.0652238826939,
      "중랑물재생센터 풋살장",
      true);
  addLocation(
      "서울 성동구 응봉동 9-4",
      "체육시설",
      "체육시설",
      "02-2293-7646",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55747733628453,
      127.02167742687156,
      "응봉공원 게이트볼장",
      true);
  addLocation(
      "서울 성동구 응봉동 9-4",
      "체육시설",
      "체육시설",
      "02-2293-7646",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.55747733628453,
      127.02167742687156,
      "응봉공원 테니스장",
      true);
  addLocation(
      "성동구 성수동1가 685-164",
      "체육시설",
      "체육시설",
      "02-460-2919",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.546605883004844,
      127.04019287104882,
      "서울숲 테니스장",
      true);
  addLocation(
      "성동구 성수동1가 685-164",
      "체육시설",
      "체육시설",
      "02-460-2919",
      "http://dsdskm.com/nodisable/seongdonggu/base.jpg",
      37.546605883004844,
      127.04019287104882,
      "서울숲 게이트볼장",
      true);
}

void addLocation(
    String address,
    String category,
    String category2,
    String contact,
    String base,
    double lat,
    double lon,
    String name,
    bool use) {
  int time = DateTime.now().millisecondsSinceEpoch;
  Firestore.instance
      .collection('location')
      .document("SportsFacilities" + time.toString())
      .setData({
    "address": address,
    "category1": category,
    "category2": category,
    "contact": contact,
    "image": {"base": "$base"},
    "latitude": lat,
    "longitude": lon,
    "name": name,
    "using": use,
  });
}

void addTestLocation(
    String collection,
    String docu_prefix,
    String address,
    String category,
    String category2,
    String contact,
    String base,
    double lat,
    double lon,
    String name,
    bool use) {
  int time = DateTime.now().millisecondsSinceEpoch;
  Firestore.instance
      .collection(collection)
      .document("docu_prefix" + time.toString())
      .setData({
    "address": address,
    "category1": category,
    "category2": category,
    "contact": contact,
    "image": {"base": "$base"},
    "latitude": lat,
    "longitude": lon,
    "name": name,
    "using": use,
  });
}

_addNoticeText(String title, String content, String image) {
  int time = DateTime.now().millisecondsSinceEpoch;
  Firestore.instance.collection('notice').document(time.toString()).setData({
    'title': title,
    "content": content,
    "image": image,
    "time": time.toString(),
  });
}

addNoticeText() {
  _addNoticeText("공지사항1","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항2","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항3","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항4","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항555555555555555555","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항6","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항7","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항8","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항9","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
  _addNoticeText("공지사항10","내용1","http://dsdskm.com/nodisable/seongdonggu/image4.jpg");
}
