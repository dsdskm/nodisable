class NaviData {
  String type;
  dynamic coordinates;
  int index;
  int pointIndex;
  String name;
  String guidePointName;
  String description;
  int turnType;
  String pointType;


  NaviData(this.type, this.coordinates, this.index, this.pointIndex, this.name,
      this.guidePointName, this.description, this.turnType, this.pointType);

  @override
  String toString() {
    return 'NaviData{type: $type, coordinates: $coordinates, index: $index, pointIndex: $pointIndex, name: $name, guidePointName: $guidePointName, description: $description, turnType: $turnType, pointType: $pointType}';
  }

// factory NaviData.fromJson(Map<String, dynamic> json) {
  //   return NaviData(
  //       coordinates: json["coordinates"] as List<List<double>>,
  //       index: json["index"] as int,
  //       pointIndex: json["pointIndex"] as int,
  //       name: json["name"] as String,
  //       guidePointName: json["guidePointName"] as String,
  //       description: json["description"] as String,
  //       turnType: json["turnType"] as int,
  //       pointType: json["pointType"] as String);
  // }
}
