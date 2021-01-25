class SearchResultData {
  String address;
  String address2;
  double latitude;
  double longitude;
  double distance;

  SearchResultData(this.address, this.address2, this.latitude, this.longitude,
      this.distance);

  @override
  String toString() {
    return 'SearchResultData{address: $address, address2: $address2, latitude: $latitude, longitude: $longitude, distance: $distance}';
  }
}
