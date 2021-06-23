import 'package:floor/floor.dart';

@Entity(tableName: 'placeTable')
class PlaceData {
  @PrimaryKey(autoGenerate: true)
  int uid;
  String docu;
  String address;
  String category1;
  String category2;
  String contact;
  bool elevator;
  String floor;
  bool gyungsaro;
  double latitude;
  double longitude;
  String name;
  bool parking;
  bool restroom;
  String summary;
  bool using;
  String image_base;
  String image_elevator;
  String image_gyungsaro;
  String image_parking;
  String image_restroom;
  String arr_image_elevator;
  String arr_image_gyungsaro;
  String arr_image_parking;
  String arr_image_restroom;

  PlaceData(
      this.docu,
      this.address,
      this.category1,
      this.category2,
      this.contact,
      this.elevator,
      this.floor,
      this.gyungsaro,
      this.latitude,
      this.longitude,
      this.name,
      this.parking,
      this.restroom,
      this.summary,
      this.using,
      this.image_base,
      this.image_elevator,
      this.image_gyungsaro,
      this.image_parking,
      this.image_restroom,
      this.arr_image_elevator,
      this.arr_image_gyungsaro,
      this.arr_image_parking,
      this.arr_image_restroom);

  @override
  String toString() {
    return 'PlaceData{uid: $uid, docu: $docu, address: $address, category1: $category1, category2: $category2, contact: $contact, elevator: $elevator, floor: $floor, gyungsaro: $gyungsaro, latitude: $latitude, longitude: $longitude, name: $name, parking: $parking, restroom: $restroom, summary: $summary, using: $using, image_base: $image_base, image_elevator: $image_elevator, image_gyungsaro: $image_gyungsaro, image_parking: $image_parking, image_restroom: $image_restroom, arr_image_elevator: $arr_image_elevator, arr_image_gyungsaro: $arr_image_gyungsaro, arr_image_parking: $arr_image_parking, arr_image_restroom: $arr_image_restroom}';
  }
}
