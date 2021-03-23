import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts_improved/flutter_tts_improved.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:naver_map_plugin/naver_map_plugin.dart';
import 'package:ndialog/ndialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen/screen.dart';

import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/util.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/naviData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';
import 'package:seongdonggu/data/dto/searchResultData.dart';
import 'package:seongdonggu/imageView.dart';
import 'package:seongdonggu/network/worker.dart';
import 'package:seongdonggu/noticeView.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stack/stack.dart' as MyStack;
import 'commentView.dart';

class MainView extends StatelessWidget {
  static String route = "/mainView";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => new MainViewWidget(),
      NoticeView.route: (BuildContext context) => NoticeViewWidget(),
    }, home: MainViewWidget());
  }
}

class MainViewWidget extends StatefulWidget {
  @override
  MainViewState createState() => MainViewState();
}

class MainViewState extends State<MainViewWidget> with WidgetsBindingObserver {
  double MAP_WIDTH = SIZE_WIDTH;
  double MAP_HEIGHT = SIZE_HEIGHT;
  Position _current_position;

  int _selectedCategoryRadius = 0;
  int _selectedCategory1 = 0;
  int _selectedCategory2 = 0;
  bool _isShowingMapOnly = true;
  PlaceData _currentPlaceData;
  SearchResultData _searchResultData;
  Timer _timer;
  List<PathOverlay> _polyLineList = List<PathOverlay>();
  static double _zoom = 14;
  static double _zoom_init = 13;
  static double MAX_ZOOM = 18;
  bool _isNaviStarted = false;
  String _currentTtsDescription = "";
  bool _isUsingTTS = false;

  NaverMapController _controller;
  CameraPosition CAMERA_POSITION_CENTER = CameraPosition(
    target: LatLng(37.561171, 127.035712),
    zoom: _zoom_init,
  );
  MyStack.Stack<NaviData> NAVI_DATA_STACK = MyStack.Stack<NaviData>();
  bool _isInitDrop = false;

  List<SearchResultData> SEARCH_RESULT_LIST = List();
  var geolocator = Geolocator();
  var locationOptions = LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      forceAndroidLocationManager: true,
      timeInterval: 1);

  Map<String, double> _distanceHash = new HashMap();
  List<LatLng> LATLNG_LIST = new List();

  List<DropdownMenuItem> dropDownMenuRadiusItemList = new List();

  List<DropdownMenuItem> dropDownMenuItemList = new List();
  List<String> dropDownList = new List();
  Set<String> dropDownMenuItemSet = new Set();

  HashMap<String, List<DropdownMenuItem>> dropDownHash = new HashMap();
  HashMap<String, List<String>> dropDownStringHash = new HashMap();

  ProgressDialog _progressDialog;

  void trackGeoLocation() async {
    print("trackGeoLocation");
    final PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location);
    if (permission == PermissionStatus.granted) {
      fetchLocation();
    } else {
      askPermission();
    }
  }

  void askPermission() {
    print("askPermission");
    PermissionHandler().requestPermissions(
        [PermissionGroup.locationWhenInUse]).then(__onStatusRequested);
  }

  void __onStatusRequested(Map<PermissionGroup, PermissionStatus> statuses) {
    print("__onStatusRequested");
    final status = statuses[PermissionGroup.locationWhenInUse];
    print("__onStatusRequested wheninuse $status");
    final status2 = statuses[PermissionGroup.locationAlways];
    print("__onStatusRequested always $status2");
  }

  void fetchLocation() async {
    print("fetchLocation");
    askPermission();
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true)
        .timeout(Duration(seconds: CURRENT_LOCATION_CHECK_DELAY))
        .then((value) {
      print("fetchLocation _current_position $value");
      setState(() {
        _current_position = value;
      });
    });
  }

  startLocationMonitoring() {
    print("startLocationMonitoring");
    if (_timer != null) {
      _timer.cancel();
    }
    getCurrentLocation();
    _timer = Timer.periodic(Duration(seconds: CURRENT_LOCATION_CHECK_DELAY),
            (timer) {
          getCurrentLocation();
        });
  }

  StreamBuilder _streamBuilder;

  getStreamBuilder() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(COLLECTION_LOCATION)
            .snapshots(),
        builder: (context, snapshot) {
          print("snapshot _currentPlaceData docu ${_currentPlaceData.docu}");
          if (snapshot.hasData) {
            for (int i = 0; i < snapshot.data.docs.length; i++) {
              Map<String, dynamic> ds = snapshot.data.docs[i].data();
              String id = snapshot.data.docs[i].id;
              if (id != _currentPlaceData.docu) {
                continue;
              }
              String address = nullCheck(ds[FIELD_ADDRESS]);
              String category1 = nullCheck(ds[FIELD_CATEGORY1]);
              String category2 = nullCheck(ds[FIELD_CATEGORY2]);
              String contact = nullCheck(ds[FIELD_CONTACT]);
              bool elevator = ds[FIELD_ELEVATOR];
              String floor = nullCheck(ds[FIELD_FLOOR]);
              bool gyungsaro = ds[FIELD_GYUNGSARO];
              double latitude = ds[FIELD_LATITUDE];
              double longitude = ds[FIELD_LONGITUDE];
              String name = nullCheck(ds[FIELD_NAME]);
              bool parking = ds[FIELD_PARKING];
              bool restroom = ds[FIELD_RESTROOM];
              String summary = nullCheck(ds[FIELD_SUMMARY]);
              bool using = ds[FIELD_USING];
              Map<dynamic, dynamic> image = ds[FIELD_IMAGE];
              String image_base = "";
              String image_elevator = "";
              String image_gyungsaro = "";
              String image_parking = "";
              String image_restroom = "";
              if (image != null) {
                image_base = nullCheck(image[FIELD_IMAGE_BASE]);
                image_elevator =
                    nullImageCheck(image[FIELD_IMAGE_ELEVATOR], image_base);
                image_gyungsaro =
                    nullImageCheck(image[FIELD_IMAGE_GYUNGSARO], image_base);
                image_parking =
                    nullImageCheck(image[FIELD_IMAGE_PARKING], image_base);
                image_restroom =
                    nullImageCheck(image[FIELD_IMAGE_RESTROOM], image_base);
              }
              PlaceData pd = PlaceData(
                  id,
                  address,
                  category1,
                  category2,
                  contact,
                  elevator,
                  floor,
                  gyungsaro,
                  latitude,
                  longitude,
                  name,
                  parking,
                  restroom,
                  summary,
                  using,
                  image_base,
                  image_elevator,
                  image_gyungsaro,
                  image_parking,
                  image_restroom);
              DATABASE.placeDao.insertData(pd);
              _currentPlaceData = pd;
            }
            return detailView();
          } else {
            return Container();
          }
        });
  }

  @override
  void initState() {
    super.initState();
    print("initState");
    Screen.keepOn(true);
    startLocationMonitoring();

    _flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });
    _flutterTts.setCompletionHandler(() {
      ttsState = TtsState.stopped;
    });
    _flutterTts.setErrorHandler((message) {
      ttsState = TtsState.stopped;
    });
    WidgetsBinding.instance.addObserver(this);
    _streamBuilder = getStreamBuilder();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("didChangeAppLifecycleState paused");
    }
    if (state == AppLifecycleState.resumed) {
      print("didChangeAppLifecycleState resumed");
      // Navigator.popAndPushNamed(context, MainView.route);
    }
  }

  moveCameraPositionSimply(double lat, double lon, [double zoom]) {
    print("moveCameraPositionSimply lat $lat lon $lat zoom $zoom");
    if (zoom != null) {
      CAMERA_POSITION_CENTER =
          CameraPosition(target: LatLng(lat, lon), zoom: zoom);
    } else {
      CAMERA_POSITION_CENTER = CameraPosition(target: LatLng(lat, lon));
    }
    if (_controller != null) {
      _controller
          .moveCamera(CameraUpdate.toCameraPosition(CAMERA_POSITION_CENTER));
    }
  }

  moveCameraPosition(double lat, double lon, double bearing, bool fit,
      [int gap]) {
    print("moveCameraPosition lat $lat lon $lat bearing $bearing");
    double zoom = MAX_ZOOM;
    if (fit && gap != null) {
      switch (gap) {
        case 0:
          zoom = 16;
          break;
        case 1:
          zoom = 15.5;
          break;
        case 2:
          zoom = 15;
          break;
        case 3:
          zoom = 14.5;
          break;
        case 4:
          zoom = 14;
          break;
        default:
          zoom = MAX_ZOOM;
      }
    }

    print(
        "moveCameraPosition zoom $zoom gap $gap bearing $bearing fit $fit LATLNG_LIST ${LATLNG_LIST
            .length}");
    CAMERA_POSITION_CENTER =
        CameraPosition(target: LatLng(lat, lon), zoom: zoom, bearing: bearing);

    if (_controller != null) {
      _controller
          .moveCamera(CameraUpdate.toCameraPosition(CAMERA_POSITION_CENTER));
    }
  }

  getCurrentLocation() async {
    print("getCurrentLocation");
    await Geolocator.checkPermission();
    _current_position = await Geolocator.getCurrentPosition();
    print("getCurrentLocation _current_position $_current_position");
    askPermission();
    if (DEBUG && _isNaviStarted) {
      _current_position = getFakePosition();
    }
    print(
        "getCurrentLocation _isNaviStarted $_isNaviStarted current $_current_position");
    if (_isNaviStarted) {
      checkDistance();
    } else {
      makeList();
      setState(() {});
    }
  }

  List<Marker> markers = new List();

  Widget mapWidgetPortrait() {
    print("mapWidgetPortrait");
    var orientation = MediaQuery
        .of(context)
        .orientation;
    if (orientation == Orientation.portrait) {
      return mapView(SIZE_WIDTH, SIZE_HEIGHT);
    } else {
      return Container();
    }
  }

  Widget mapWidgetLand() {
    print("mapWidgetLand");
    var orientation = MediaQuery
        .of(context)
        .orientation;
    if (orientation == Orientation.landscape) {
      return mapView(SIZE_WIDTH, SIZE_HEIGHT);
    } else {
      return Container();
    }
  }

  Widget mapView(width, height) {
    print("mapView width $width height $height");
    return Container(
        padding: EdgeInsets.only(top: PADDING_TOP + TOP_BAR_HEIGHT),
        width: width,
        height: height,
        child: NaverMap(
          pathOverlays: _polyLineList.toSet(),
          initialCameraPosition: CAMERA_POSITION_CENTER,
          markers: createMarker(),
          // circles: createCircle(),
          tiltGestureEnable: true,
          mapType: MapType.Basic,
          onMapCreated: (controller) {
            _controller = controller;
          },
          rotationGestureEnable: true,
          locationButtonEnable: true,
          // initLocationTrackingMode: LocationTrackingMode.Follow,
          zoomGestureEnable: true,
          onMapTap: (latLng) {
            hideDetail();
          },
          onMapDoubleTap: (latLng) {
            hideDetail();
          },
        ));
  }

  Marker _currentLocationMarker;

  List<Marker> createMarker() {
    markers.clear();
    print("createMarker list ${FILTERED_LIST.length}");
    for (int i = 0; i < FILTERED_LIST.length; i++) {
      PlaceData data = FILTERED_LIST[i];
      double distance = _distanceHash[data.docu];

      String title =
          "${data.name}[~${distance.toInt()}m]\n${data.address.replaceAll(
          "서울시 성동구 ", "")}";
      print("info title $title");
      Marker marker = Marker(
          markerId: data.docu,
          width: 20,
          height: 30,
          position: LatLng(data.latitude, data.longitude),
          infoWindow: title,
          onMarkerTab: (marker, iconSize) {
            stopNavi();
            showDetailView(data);
          });
      markers.add(marker);
    }

    if (_current_position != null) {
      print("createMarker _current_position $_current_position");
      if (_currentLocationMarker != null) {
        markers.remove(_currentLocationMarker);
      }
      _currentLocationMarker = Marker(
        markerId: "current",
        position:
        LatLng(_current_position.latitude, _current_position.longitude),
        iconTintColor: Colors.blue,
        infoWindow: StringClass.CURRENT_LOCATION,
      );
      markers.add(_currentLocationMarker);
    }

    for (int i = 0; i < NAVI_LIST.length; i++) {
      NaviData n = NAVI_LIST[i];
      for (int j = 0; j < n.coordinates.length; j++) {
        if (n.coordinates != null) {
          Marker m = Marker(
            markerId: "navi$i$j",
            position: LatLng(n.coordinates[j][1], n.coordinates[j][0]),
            iconTintColor: Color.fromARGB(255, 255, 0, 0),
          );
          markers.add(m);
        }
      }
    }

    for (int i = 0; i < SEARCH_RESULT_LIST.length; i++) {
      SearchResultData data = SEARCH_RESULT_LIST[i];
      double distance = Geolocator.distanceBetween(_current_position.latitude,
          _current_position.longitude, data.latitude, data.longitude);
      String title = "${data.address}[~${distance.toInt()}m]";
      print("info title $title");
      Marker m = Marker(
          markerId: "search$i",
          position: LatLng(data.latitude, data.longitude),
          infoWindow: title,
          iconTintColor: Color.fromARGB(255, 0, 255, 0),
          onMarkerTab: (marker, iconSize) {
            showSearchResultView(data);
          });
      markers.add(m);
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    setSize(MediaQuery.of(context));
    appVersionCheck(context);
    initDropDownList();
    print("build isShowingMap $_isShowingMapOnly");
    _progressDialog = new ProgressDialog(
      context,
      message: Text(StringClass.NAVI_LOADING),
    );
    var orientation = MediaQuery
        .of(context)
        .orientation;
    return WillPopScope(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(children: [
              mapWidgetPortrait(),
              mapWidgetLand(),
              dropDownView(),
              menuView(),
              searchView(),
              _isShowingMapOnly ? Container() : detailView_()
            ])),
        onWillPop: () async {
          showExitDialog();
          return false;
        });
  }

  void showExitDialog() {
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: new Text(StringClass.DIALOG_TITLE_EXIT),
              content: new Text(StringClass.DIALOG_MESSAGE_EXIT),
              actions: <Widget>[
                new FlatButton(
                  child: new Text(StringClass.YES),
                  onPressed: () {
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                ),
                new FlatButton(
                  child: new Text(StringClass.NO),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  },
                ),
              ],
            ));
  }

  void initDropDownList() {
    print("initDropDownList");
    dropDownList.clear();
    dropDownMenuItemList.clear();
    dropDownMenuItemSet.clear();
    dropDownHash.clear();
    List<CategoryData> list = CATEGORY_LIST;
    print("initDropDownList list $list");
    // depth 1
    for (int i = 0; i < list.length; i++) {
      CategoryData data = list[i];
      if (data.depth == 0) {
        DropdownMenuItem menuItem = DropdownMenuItem(
            child: Container(
                width: 70,
                child: AutoSizeText(
                  data.value,
                  minFontSize: 5,
                  style: TextStyle(fontSize: 15),
                )),
            value: dropDownMenuItemList.length);
        dropDownMenuItemSet.add(data.value);
        dropDownList.add(data.value);
        dropDownMenuItemList.add(menuItem);
        dropDownHash[data.value] = List<DropdownMenuItem>();
        dropDownStringHash[data.value] = List<String>();
      }
    }
    // depth 2
    int index = 0;
    for (int i = 0; i < list.length; i++) {
      CategoryData data = list[i];
      if (data.depth == 1) {
        DropdownMenuItem submenuItem = DropdownMenuItem(
            child: Container(
                width: 80,
                child: AutoSizeText(
                  data.value,
                  minFontSize: 5,
                  style: TextStyle(fontSize: 15),
                )),
            value: data.index);
        dropDownHash[data.category].add(submenuItem);
        dropDownStringHash[data.category].add(data.value);
        index++;
      }
    }
    // radius
    dropDownMenuRadiusItemList.clear();

    for (int i = 0; i < RADIUS.length; i++) {
      var dropdown = DropdownMenuItem(
          child: Container(
              width: 70,
              child: AutoSizeText(
                RADIUS[i],
                minFontSize: 5,
                style: TextStyle(fontSize: 15),
              )),
          value: dropDownMenuRadiusItemList.length);
      dropDownMenuRadiusItemList.add(dropdown);
    }
  }

  menuView() {
    print("menuView");
    return Align(
        alignment: Alignment.topRight,
        child: Container(
            margin: EdgeInsets.only(right: 10, left: 10, top: 10 + PADDING_TOP),
            color: Colors.transparent,
            child: PopupMenuButton<int>(
              itemBuilder: (context) =>
              [
                PopupMenuItem(value: 4, child: Text(StringClass.GO_UPDATE)),
                PopupMenuItem(value: 0, child: Text(StringClass.NOTICE)),
                PopupMenuItem(value: 1, child: Text(StringClass.REVIEW)),
                PopupMenuItem(value: 2, child: Text(StringClass.OSS)),
                PopupMenuItem(value: 3, child: Text(StringClass.EXIT)),
              ],
              onSelected: (value) => {menuSelected(value)},
            )));
  }

  menuSelected(int value) {
    switch (value) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => NoticeViewWidget(),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => CommentViewWidget(),
          ),
        );
        break;
      case 2:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => LicensePage()));
        break;
      case 3:
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        break;
      case 4:
        Navigator.popAndPushNamed(context, MainView.route);
        break;
    }
  }

  void showSearchResultView(SearchResultData data) {
    print("showSearchResultView data $data");
    _currentPlaceData = null;
    _searchResultData = data;

    setState(() {
      _isShowingMapOnly = false;
      moveCameraPositionSimply(data.latitude, data.longitude, MAX_ZOOM);
      initState();
    });
  }

  void showDetailView(PlaceData data) {
    print("showDetailView");
    _searchResultData = null;
    _currentPlaceData = data;
    setState(() {
      _isShowingMapOnly = false;
      moveCameraPositionSimply(
          _currentPlaceData.latitude, _currentPlaceData.longitude, MAX_ZOOM);
    });
  }

  searchTitleView(bool portrait) {
    var width;
    if (portrait) {
      width = SIZE_WIDTH;
    } else {
      width = SIZE_WIDTH / 2;
    }
    print("titleView width $width portrait $portrait");
    return Container(
        margin: EdgeInsets.only(top: 0),
        padding: EdgeInsets.only(top: 0, bottom: 0),
        alignment: Alignment.topCenter,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              StringClass.ROAD_ADDRESS,
              style: TextStyle(fontSize: getFont(10, context)),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            AutoSizeText(
              _searchResultData.address,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: getFont(11, context)),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.only(top: 5)),
          ],
        ));
  }

  titleView(bool portrait) {
    var width;
    if (portrait) {
      width = SIZE_WIDTH;
    } else {
      width = SIZE_WIDTH / 2;
    }
    print("titleView width $width portrait $portrait");
    return Container(
        margin: EdgeInsets.only(top: 0),
        padding: EdgeInsets.only(top: 0),
        alignment: Alignment.center,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              style: TextStyle(fontSize: getFont(9, context)),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            _currentPlaceData.summary.length > 0
                ? AutoSizeText(
              _currentPlaceData.summary,
              style: TextStyle(fontSize: getFont(8, context)),
              maxLines: 1,
              textAlign: TextAlign.center,
            )
                : Container(),
          ],
        ));
  }

  detailView_() {
    print(
        "detailView_ isNaviStarted $_isNaviStarted _isShowingMapOnly $_isShowingMapOnly");
    if (_searchResultData != null) {
      return searchDetailView();
    } else {
      if (_isNaviStarted || !_isShowingMapOnly) {
        return getStreamBuilder();
      } else {
        return _streamBuilder;
      }
    }
  }

  searchDetailView() {
    if (_searchResultData != null) {
      var orientation = MediaQuery
          .of(context)
          .orientation;
      var height;
      String title = _searchResultData.address;
      if (orientation == Orientation.portrait) {
        if (_isNaviStarted) {
          return Align(
              alignment: Alignment.bottomCenter,
              child: Wrap(children: [naviDetailContentView(title, true)]));
        } else {
          height = SIZE_HEIGHT - MAP_HEIGHT;
          return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  alignment: Alignment.center,
                  height: height,
                  child: Wrap(
                    children: [
                      searchTitleView(true),
                      searchBottomView(true),
                    ],
                  )));
        }
      } else {
        if (_isNaviStarted) {
          return Align(
              alignment: Alignment.bottomRight,
              child: naviDetailContentView(title, false));
        } else {
          return Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  width: SIZE_WIDTH / 2,
                  height: SIZE_HEIGHT - TOP_BAR_HEIGHT - PADDING_TOP,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Expanded(child: searchTitleView(false), flex: 2),
                      Expanded(child: searchBottomView(false), flex: 1),
                    ],
                  )));
        }
      }
    }
  }

  detailView() {
    print(
        "detailView _isNaviStarted $_isNaviStarted _currentPlaceData $_currentPlaceData");
    var orientation = MediaQuery
        .of(context)
        .orientation;
    if (_currentPlaceData != null) {
      String title =
          "[${_currentPlaceData.category2}]${_currentPlaceData.name}";
      if (orientation == Orientation.portrait) {
        if (_isNaviStarted) {
          return Align(
              alignment: Alignment.bottomCenter,
              child: Wrap(children: [naviDetailContentView(title, true)]));
        } else {
          return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  margin: EdgeInsets.all(1),
                  decoration: BOX_DECORATION,
                  height: SIZE_HEIGHT * 0.3,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Expanded(child: titleView(true), flex: 2),
                      Expanded(child: tabView(true), flex: 3),
                      Expanded(child: bottomView(true), flex: 2),
                    ],
                  )));
        }
      } else {
        if (_isNaviStarted) {
          return Align(
              alignment: Alignment.bottomRight,
              child: naviDetailContentView(title, false));
        } else {
          return Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  margin: EdgeInsets.all(1),
                  decoration: BOX_DECORATION,
                  width: SIZE_WIDTH / 2.5,
                  height: SIZE_HEIGHT - TOP_BAR_HEIGHT - PADDING_TOP,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Expanded(child: titleView(false), flex: 1),
                      Expanded(child: tabView(false), flex: 2),
                      Expanded(child: bottomView(false), flex: 1),
                    ],
                  )));
        }
      }
    }

    return Container();
  }

  naviDetailContentView(String title, bool portrait) {
    print("naviDetailContentView $_currentTtsDescription portrait $portrait");
    var width;
    var height;
    if (portrait) {
      width = SIZE_WIDTH;
      height = SIZE_HEIGHT * 0.2;
      return Container(
        width: width,
        height: height,
        padding: EdgeInsets.only(top: 0),
        margin: EdgeInsets.all(1),
        decoration: BOX_DECORATION,
        alignment: Alignment.bottomCenter,
        child: Column(
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(left: 2, right: 2),
                alignment: Alignment.center,
                child: AutoSizeText(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: getFont(10, context)),
                  maxLines: 2,
                )),
            _currentTtsDescription.length > 0
                ? AutoSizeText(_currentTtsDescription,
                style: TextStyle(fontSize: getFont(10, context)),
                maxLines: 1)
                : Container(),
            Container(
                margin: EdgeInsets.only(top: 5),
                width: SIZE_WIDTH,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        child: FlatButton(
                          child: AutoSizeText(
                            StringClass.RESTARTED,
                            style: TextStyle(fontSize: getFont(10, context)),
                          ),
                          onPressed: () {
                            _progressDialog.show();
                            isPassedFirstPos = false;
                            getOverlay(true);
                            if (_isUsingTTS) {
                              _flutterTts.speak(StringClass.TTS_RESTARTED);
                            }
                          },
                        )),
                    Container(
                        child: FlatButton(
                          child: AutoSizeText(
                            StringClass.CANCEL,
                            style: TextStyle(fontSize: getFont(10, context)),
                          ),
                          onPressed: () {
                            _isNaviStarted = false;
                            // _controller.hideMarkerInfoWindow(
                            //     MarkerId(_currentPlaceData.docu));

                            stopNavi();
                            if (_isUsingTTS) {
                              _flutterTts.speak(StringClass.TTS_CANCELED);
                            }
                            hideDetail();
                          },
                        ))
                  ],
                ))
          ],
        ),
      );
    } else {
      width = NAVI_DETAIL_RIGHT_WIDTH;
      height = SIZE_HEIGHT - TOP_BAR_HEIGHT - PADDING_TOP;
      var summaryTitle = "";
      if (_currentPlaceData != null) {
        summaryTitle =
        "[${_currentPlaceData.category2}]${_currentPlaceData.name}";
      } else if (_searchResultData != null) {
        summaryTitle = _searchResultData.address;
      }
      return Container(
        width: width,
        height: height,
        margin: EdgeInsets.all(1),
        decoration: BOX_DECORATION,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(left: 2, right: 2),
                alignment: Alignment.center,
                child: AutoSizeText(
                  summaryTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: getFont(10, context)),
                  maxLines: 3,
                )),
            _currentTtsDescription.length > 0
                ? AutoSizeText(_currentTtsDescription,
                style: TextStyle(fontSize: getFont(10, context)),
                maxLines: 1)
                : Container(),
            Container(
                child: FlatButton(
                  child: AutoSizeText(
                    StringClass.RESTARTED,
                    style: TextStyle(fontSize: getFont(10, context)),
                  ),
                  onPressed: () {
                    naviRestart();
                  },
                )),
            Container(
                child: FlatButton(
                  child: AutoSizeText(
                    StringClass.CANCEL,
                    style: TextStyle(fontSize: getFont(10, context)),
                  ),
                  onPressed: () {
                    _isNaviStarted = false;
                    // _controller.hideMarkerInfoWindow(
                    //     MarkerId(_currentPlaceData.docu));

                    stopNavi();
                    if (_isUsingTTS) {
                      _flutterTts.speak(StringClass.TTS_CANCELED);
                    }
                    hideDetail();
                  },
                ))
          ],
        ),
      );
    }
  }

  naviRestart() {
    print("naviRestart");
    _progressDialog.show();
    isPassedFirstPos = false;
    getOverlay(true);
    if (_isUsingTTS) {
      _flutterTts.speak(StringClass.TTS_RESTARTED);
    }
  }

  tabView(bool portrait) {
    var width;
    var height;
    if (portrait) {
      width = SIZE_WIDTH;
      height = SIZE_HEIGHT / 5;
    } else {
      width = SIZE_WIDTH / 2;
      height = SIZE_HEIGHT / 2;
    }
    print("tabView width $width height $height portrait $portrait");
    return DefaultTabController(
      length: 4,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: <Widget>[
            Container(
                height: 30,
                padding: EdgeInsets.all(1),
                child: TabBar(
                  indicatorColor: Colors.blue,
                  indicatorWeight: 1,
                  indicatorPadding: EdgeInsets.all(0),
                  indicator: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: const BorderRadius.all(
                        const Radius.circular(999.0),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.blueAccent, blurRadius: 6.0)
                      ]),
                  tabs: <Widget>[
                    Tab(
                      child: AutoSizeText(
                        StringClass.TAB_LABEL_GYUNGSARO,
                        maxLines: 1,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: getFont(12, context)),
                      ),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_RESTROOM,
                          minFontSize: 5,
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: getFont(12, context))),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_ELEVATOR,
                          maxLines: 1,
                          minFontSize: 1,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: getFont(12, context))),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_PARKING,
                          maxLines: 1,
                          minFontSize: 1,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: getFont(12, context))),
                    ),
                  ],
                )),
            Padding(padding: EdgeInsets.all(1)),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  getTapImageView(_currentPlaceData.image_gyungsaro),
                  getTapImageView(_currentPlaceData.image_restroom),
                  getTapImageView(_currentPlaceData.image_elevator),
                  getTapImageView(_currentPlaceData.image_parking)
                ],
              ),
            ),
            Padding(padding: EdgeInsets.all(1)),
          ],
        ),
      ),
    );
  }

  getTapImageView(String path) {
    print("getTapImageView path $path");
    if (path == null || path.isEmpty) {
      path =
      "https://firebasestorage.googleapis.com/v0/b/nodisable.appspot.com/o/ready.png?alt=media&token=6a6b0cee-e3a3-4354-9ba7-7cfd1d835145";
      return Container(
          child: Stack(
            children: [
              Container(
                  alignment: Alignment.center,
                  child: FlatButton(
                    child: Image.network(path),
                    onPressed: () {
                      showImage(path);
                    },
                  )),
              Container(
                  alignment: Alignment.center,
                  child: FlatButton(
                    onPressed: () {
                      showImage(path);
                    },
                    child: Text(
                      StringClass.READY,
                      style: TextStyle(backgroundColor: Colors.white),
                    ),
                  ))
            ],
          ));
    } else {
      return Container(
        alignment: Alignment.center,
        child: FlatButton(
          child: Image.network(path),
          onPressed: () {
            showImage(path);
          },
        ),
      );
    }
  }

  searchBottomView(bool portrait) {
    var width;
    if (portrait) {
      width = SIZE_WIDTH;
    } else {
      width = SIZE_WIDTH / 2;
    }
    return Container(
        width: width,
        alignment: Alignment.bottomCenter,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/navi.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.NAVI,
                minFontSize: 1,
                maxFontSize: getFont(10, context),
              ),
            ]),
            onPressed: () {
              print("current location $_current_position");
              fake_index = 0;
              showTtsSelectDialog(
                  _searchResultData.latitude, _searchResultData.longitude);
            },
          ),
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/cancel.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.CANCEL,
                minFontSize: 1,
                maxFontSize: getFont(10, context),
              ),
            ]),
            onPressed: () {
              stopNavi();
              hideDetail();
            },
          ),
        ]));
  }

  bottomView(bool portrait) {
    var width;
    if (portrait) {
      width = SIZE_WIDTH;
    } else {
      width = SIZE_WIDTH / 2;
    }
    print("bottomView width $width portrait $portrait");
    return Container(
        width: width,
        alignment: Alignment.bottomCenter,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/navi.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.NAVI,
                minFontSize: 1,
                maxFontSize: getFont(10, context),
              ),
            ]),
            onPressed: () {
              print("current location $_current_position");
              fake_index = 0;
              showTtsSelectDialog(
                  _currentPlaceData.latitude, _currentPlaceData.longitude);
            },
          ),
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/call.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.CALL,
                minFontSize: 1,
                maxFontSize: getFont(10, context),
              ),
            ]),
            onPressed: () {
              print("current location $_current_position");
              launch(('tel://${_currentPlaceData.contact}'));
            },
          ),
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/cancel.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.CANCEL,
                minFontSize: 1,
                maxFontSize: getFont(10, context),
              ),
            ]),
            onPressed: () {
              stopNavi();
              hideDetail();
            },
          ),
        ]));
  }

  showSearchDialog() {
    TextEditingController _controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: new Text(StringClass.DIALOG_TITLE_SEARCH),
              content: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                    hintText: StringClass.DIALOG_MESSAGE_SEARCH),
                controller: _controller,
              ),
              actions: [
                FlatButton(
                    onPressed: () {
                      _controller.clear();
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                    },
                    child: Text(StringClass.CANCEL)),
                FlatButton(
                    onPressed: () {
                      showToast(_controller.text);
                      getSearchResult(
                          _controller.text,
                          _current_position.latitude,
                          _current_position.longitude)
                          .then((value) {
                        SEARCH_RESULT_LIST = value;
                        showToast(
                            "총 ${SEARCH_RESULT_LIST.length} 개의 검색 결과가 있습니다.");
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        setState(() {});
                      });
                      _controller.clear();
                    },
                    child: Text(StringClass.SEARCH)),
              ],
            ));
  }

  hideDetail() {
    print("hideDetail");
    if (_polyLineList.length > 0) {
      _polyLineList.clear();
    }
    NAVI_LIST = new List();
    setState(() {
      _isShowingMapOnly = true;
      _currentPlaceData = null;
    });
  }

  void getOverlay(bool start) async {
    print("getOverlay");
    if (_isUsingTTS) {
      print("requestDirection tts play ${StringClass.TTS_STARTED}");
      _flutterTts.speak(StringClass.TTS_STARTED).then((value) {
        if (value == 1) {
          ttsState = TtsState.playing;
        }
      });
    }
    _polyLineList.clear();
    double target_lat;
    double target_lon;
    if (_currentPlaceData != null) {
      target_lat = _currentPlaceData.latitude;
      target_lon = _currentPlaceData.longitude;
    } else if (_searchResultData != null) {
      target_lat = _searchResultData.latitude;
      target_lon = _searchResultData.longitude;
    }
    requestDirection(_current_position.latitude, _current_position.longitude,
        target_lat, target_lon)
        .then((value) {
      _isNaviStarted = true;
      Navigator.of(context).pop('dialog');
      // 경로 그린다
      _polyLineList = value;
      // 전체 경로 리스트중 첫번째 쪽으로 bearing 한다
      LatLng firstPosition;

      // 뒤 인덱스부터 스택에 넣는다
      for (int i = NAVI_LIST.length - 1; i >= 0; i--) {
        NaviData nv = NAVI_LIST[i];
        NAVI_DATA_STACK.push(nv);
      }
      if (NAVI_LIST.length > 0) {
        NaviData nv = NAVI_LIST[0];
        for (int j = 0; j < nv.coordinates.length; j++) {
          if (nv.coordinates != null) {
            firstPosition =
            new LatLng(nv.coordinates[j][1], nv.coordinates[j][0]);
            break;
          }
        }
      }
      setState(() {
        // 출발지점부터 첫번째 지점 까지의 베어링 계산후 적용
        var bearing = Geolocator.bearingBetween(
            _current_position.latitude,
            _current_position.longitude,
            firstPosition.latitude,
            firstPosition.longitude);
        print(
            "getOverlay getCurrentLocation  ${_current_position
                .latitude} ${_current_position.longitude} to ${firstPosition
                .latitude} ${firstPosition.longitude} bearing $value");

        moveCameraPosition(_current_position.latitude,
            _current_position.longitude, bearing, true, 99);
        setState(() {
          // initState();
        });
      });
    });
  }

  dropDownView() {
    print("dropDownView $dropDownHash");
    print("dropDownView $dropDownList");
    print("dropDownView $_selectedCategory1");
    return Container(
        height: TOP_BAR_HEIGHT,
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(right: 20, left: 0, top: PADDING_TOP),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            DropdownButton(
                value: _selectedCategory1,
                items: dropDownMenuItemList,
                onChanged: (value) {
                  _selectedCategory1 = value;
                  _selectedCategory2 = 0;
                  makeList();
                  setState(() {});
                }),
            DropdownButton(
                value: _selectedCategory2,
                items: dropDownHash[dropDownList[_selectedCategory1]],
                onChanged: (value) {
                  _selectedCategory2 = value;
                  makeList();
                  setState(() {});
                }),
          ],
        ));
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  HashMap<String, String> ttsHash = new HashMap();
  FlutterTtsImproved _flutterTts = FlutterTtsImproved();

  HashMap<int, String> ttsHashMap = new HashMap();
  HashMap<String, String> ttsHashMap2 = new HashMap();
  TtsState ttsState = TtsState.stopped;
  bool isPassedFirstPos = false;

  void checkDistance() async {
    print("checkDistance");
    if (NAVI_DATA_STACK.length == 0) {
      return;
    }
    var navStackTop = NAVI_DATA_STACK.top();
    String text = navStackTop.description;

    for (int i = 0; i < navStackTop.coordinates.length; i++) {
      var lat = navStackTop.coordinates[i][1];
      var lon = navStackTop.coordinates[i][0];

      double distance = Geolocator.distanceBetween(
          _current_position.latitude, _current_position.longitude, lat, lon);
      if (distance > 100) {
        naviRestart();
        return;
      }
      var ttsForNext = "다음 안내까지 ${distance.toInt()}m";
      showToast(ttsForNext);
      if (_isUsingTTS) {
        _flutterTts.speak(ttsForNext).then((value) {
          if (value == 1) {
            ttsState = TtsState.playing;
          }
        });
        sleep(Duration(seconds: 3));
      }
      if (navStackTop.turnType != null && navStackTop.turnType == 201) {
        if (distance < 30) {
          NAVI_DATA_STACK.pop();
          if (_isUsingTTS) {
            var ttsRes = await _flutterTts.speak(StringClass.TTS_ARRIVED);
            if (ttsRes == 1) {
              ttsState = TtsState.playing;
            }
          }
          showToast(StringClass.TTS_ARRIVED);
          stopNavi();
        }
      } else {
        print("isPassedFirstPos $isPassedFirstPos");
        int limit = 20;
        if (!isPassedFirstPos) {
          limit = 7;
        }
        if (distance < limit) {
          isPassedFirstPos = true;
          if (!ttsHashMap.containsKey(navStackTop.index)) {
            if (navStackTop.turnType != null) {
              // text = getTurnTypeText(navStackTop.turnType) + text;
            }
            if (_isUsingTTS) {
              if (text != null &&
                  text.isNotEmpty &&
                  ttsState != TtsState.playing) {
                print("checkDistance play tts $text");
                showToast(text);
                var ttsRes = await _flutterTts.speak(text);
                if (ttsRes == 1) {
                  ttsState = TtsState.playing;
                  ttsHashMap[navStackTop.index] = text;
                }
                sleep(Duration(seconds: 3));
              }
            }
          }
          NAVI_DATA_STACK.pop();
          break;
        } else {
          var bearing = Geolocator.bearingBetween(_current_position.latitude,
              _current_position.longitude, lat, lon);
          moveCameraPosition(_current_position.latitude,
              _current_position.longitude, bearing, false, 99);
          break;
        }
      }
    }
    createMarker();
    setState(() {});
  }

  void stopNavi() {
    print("stopNavi");
    NAVI_LIST.clear();
    _polyLineList.clear();
    _isNaviStarted = false;
    ttsHash.clear();
    ttsHashMap.clear();
    ttsHashMap2.clear();
    isPassedFirstPos = false;
    fake_index = 0;
    moveCameraPositionSimply(
        _current_position.latitude, _current_position.longitude);
    // MAP_HEIGHT = SIZE_HEIGHT * 0.65;
  }

  void showTtsSelectDialog(double target_lat, double target_lon) async {
    var sdk = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var v = androidInfo.version.release.trim();
      sdk = androidInfo.version.sdkInt;
      print("android version is $v sdk $sdk");
    }
    // distance check
    var distance = Geolocator.distanceBetween(_current_position.latitude,
        _current_position.longitude, target_lat, target_lon);
    print(
        "distance : $distance , limit max : $NAVI_LIMIT_DISTANCE_MAX , min : $NAVI_LIMIT_DISTANCE_MIN");
    if (NAVI_LIMIT_DISTANCE_MIN <= distance) {
      if (sdk < 0) {
        // MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
        _progressDialog.show();
        showToast("본 기기는 음성안내를 지원하지 않습니다.");
        _isUsingTTS = false;
        getOverlay(true);
      } else {
        showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: new Text(StringClass.DIALOG_TITLE_TTS),
                  content: new Text(StringClass.DIALOG_MESSAGE_TTS),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text(StringClass.YES),
                      onPressed: () {
                        _isUsingTTS = true;
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        _progressDialog.show();
                        setState(() {
                          // MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
                          print("MAP_HEIGHT $MAP_HEIGHT");
                          getOverlay(true);
                        });
                      },
                    ),
                    new FlatButton(
                      child: new Text(StringClass.NO),
                      onPressed: () {
                        _isUsingTTS = false;
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        _progressDialog.show();
                        setState(() {
                          // MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
                          print("MAP_HEIGHT $MAP_HEIGHT");
                          getOverlay(true);
                        });
                      },
                    ),
                  ],
                ));
      }
    } else {
      Fluttertoast.showToast(
          msg: StringClass.NAVI_ERR_MSG,
          backgroundColor: Colors.lightBlue,
          gravity: ToastGravity.CENTER);
    }
  }

  void showImage(String image) {
    print("showImage image $image");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ImageViewWidget(image),
      ),
    );
  }

  void makeList() {
    print("makeList PLACE_LIST ${PLACE_LIST.length}");
    FILTERED_LIST.clear();
    LATLNG_LIST.clear();
    for (int i = 0; i < PLACE_LIST.length; i++) {
      PlaceData data = PLACE_LIST[i];
      double distance = Geolocator.distanceBetween(_current_position.latitude,
          _current_position.longitude, data.latitude, data.longitude);
      _distanceHash.putIfAbsent(data.docu, () => distance);

      String category1 = data.category1;
      String category2 = data.category2;
      String selected1 = dropDownList[_selectedCategory1];
      List<String> subDropDownStringList = dropDownStringHash[selected1];
      String selected2 = subDropDownStringList[_selectedCategory2];
      print(
          "category1 $category1 category2 $category2 selected1 $selected1 selected2 $selected2");
      if (selected1.contains(category1) && category2 == selected2) {
        FILTERED_LIST.add(data);
        LATLNG_LIST.add(LatLng(data.latitude, data.longitude));
      } else if (selected1.contains(category1) &&
          selected2 == StringClass.ALL) {
        FILTERED_LIST.add(data);
        LATLNG_LIST.add(LatLng(data.latitude, data.longitude));
      } else if (category1 == StringClass.ALL) {
        FILTERED_LIST.add(data);
        LATLNG_LIST.add(LatLng(data.latitude, data.longitude));
      } else if (selected1 == StringClass.ALL && selected2 == StringClass.ALL){
        FILTERED_LIST.add(data);
        LATLNG_LIST.add(LatLng(data.latitude, data.longitude));
      }
    }
  }

  searchView() {
    print("searchView");
    Alignment align;
    if (MediaQuery
        .of(context)
        .orientation == Orientation.portrait) {
      align = Alignment.topRight;
    } else {
      align = Alignment.topLeft;
    }

    return Container(
        alignment: align,
        padding: EdgeInsets.only(top: PADDING_TOP + TOP_BAR_HEIGHT),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlatButton(
              minWidth: 50,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset("asset/images/search.jpg", width: 20, height: 20),
                AutoSizeText(
                  StringClass.SEARCH,
                  minFontSize: 1,
                  maxFontSize: getFont(10, context),
                  style: TextStyle(backgroundColor: Colors.white),
                ),
              ]),
              onPressed: () {
                showSearchDialog();
              },
            ),
            FlatButton(
                minWidth: 50,
                onPressed: () {
                  SEARCH_RESULT_LIST.clear();
                  hideDetail();
                  setState(() {});
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset("asset/images/reset.png", width: 20, height: 20),
                  AutoSizeText(
                    StringClass.RESET,
                    minFontSize: 1,
                    maxFontSize: getFont(10, context),
                    style: TextStyle(backgroundColor: Colors.white),
                  ),
                ]))
          ],
        ));
  }

  showSearchResultDialog(List list) {
    print("showSearchResultDialog list ${list.length}");
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: new Text(StringClass.DIALOG_TITLE_SEARCH),
              content: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    return buildRow(list[index]);
                  }),
            ));
  }

  buildRow(SearchResultData data) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Text(data.address),
          Text(data.address2),
          Text(data.distance.toString()),
        ],
      ),
    );
  }
}
