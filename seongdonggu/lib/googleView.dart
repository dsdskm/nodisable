import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts_improved/flutter_tts_improved.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  MainViewState createState() => MainViewState("AA");
}

class MainViewState extends State<MainViewWidget> with WidgetsBindingObserver {
  double MAP_WIDTH = SIZE_WIDTH;
  double MAP_HEIGHT = SIZE_HEIGHT;
  Position _current_position;

  int _selectedCategoryRadius = 0;
  int _selectedCategory1 = 0;
  int _selectedCategory2 = 0;
  bool _isShowingMap = true;
  PlaceData _currentPlaceData;
  Timer _timer;
  List<Polyline> _polyLineList = List<Polyline>();
  static double _zoom = 18;
  static double _zoom_init = 13;
  bool _isNaviStarted = false;
  String _currentTtsDescription = "";
  bool _isUsingTTS = false;

  GoogleMapController _controller;
  double _lastBearing = 999;
  CameraPosition CAMERA_POSITION_CENTER = CameraPosition(
    target: LatLng(37.520841, 126.983231),
    zoom: _zoom_init,
  );

  bool _isSetMapCenter = false;
  MyStack.Stack<NaviData> NAVI_DATA_STACK = MyStack.Stack<NaviData>();
  bool _isInitDrop = false;

  // test
  var geolocator = Geolocator();
  var locationOptions = LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      forceAndroidLocationManager: true,
      timeInterval: 1);

  MainViewState(String s);

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
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,
    forceAndroidLocationManager: true).timeout(Duration(seconds: 5)).then((value) {
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

  @override
  void initState() {
    super.initState();
    print("initState");
    Screen.keepOn(true);
    WidgetsBinding.instance.addObserver(this);
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
  }

  @override
  void dispose() {
    print("dispose");
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("didChangeAppLifecycleState paused");
      _timer.cancel();
      stopNavi();
    }
    if (state == AppLifecycleState.resumed) {
      print("didChangeAppLifecycleState resumed");
      Navigator.popAndPushNamed(context, MainView.route);
      startLocationMonitoring();
    }
  }

  moveCameraPosition(double bearing) {
    print("moveCameraPosition bearing $bearing");
    CAMERA_POSITION_CENTER = CameraPosition(
        target: LatLng(_current_position.latitude, _current_position.longitude),
        zoom: 18,
        bearing: bearing);
    if (_controller != null) {
      _controller
          .moveCamera(CameraUpdate.newCameraPosition(CAMERA_POSITION_CENTER));
    }
  }

  getCurrentLocation() async {
    print("getCurrentLocation by timer");
    await Geolocator.checkPermission();
    _current_position = await Geolocator.getCurrentPosition();
    askPermission();
    if (DEBUG && _isNaviStarted) {
      _current_position = getFakePosition();
    }
    print(
        "getCurrentLocation _isNaviStarted $_isNaviStarted _isSetMapCenter $_isSetMapCenter current $_current_position");
    if (!_isSetMapCenter) {
      // 마지막 베어링 유지하면서 이동
      moveCameraPosition(0);
      _isSetMapCenter = true;
      setState(() {
        updateFilteredList();
      });
    } else {}

    if (_isNaviStarted) {
      checkDistance();
    } else {
      setState(() {});
    }
  }

  Set<Marker> markers = new Set();

  Widget mapWidget() {
    print("mapWidget");
    if (!_isInitDrop) {
      updateFilteredList();
      _isInitDrop = true;
    }
    return Container(
        padding: EdgeInsets.only(top: PADDING_TOP + TOP_BAR_HEIGHT),
        width: MAP_WIDTH,
        height: MAP_HEIGHT,
        child: GoogleMap(
          polylines: _polyLineList.toSet(),
          initialCameraPosition: CAMERA_POSITION_CENTER,
          mapToolbarEnabled: false,
          markers: createMarker(),
          circles: createCircle(),
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          onTap: (LatLng latLng) {
            hideDetail();
          },
        ));
  }

// Widget mapWidget_() {
//   return FutureBuilder(
//       future: DATABASE.placeDao.getAllPlace(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           markers.clear();
//           List<PlaceData> list = snapshot.data;
//           List<PlaceData> filtered_list = List();
//           for (int i = 0; i < list.length; i++) {
//             PlaceData data = list[i];
//             String category1 = data.category1;
//             String category2 = data.category2;
//             String selected1 = dropDownList[_selectedCategory1];
//             List<String> subDropDownStringList =
//                 dropDownStringHash[selected1];
//             String selected2 = subDropDownStringList[_selectedCategory2];
//
//             double distance = await geolocator.distanceBetween(
//                 _current_position.latitude,
//                 _current_position.longitude,
//                 data.latitude,
//                 data.longitude);
//             if (selected1.contains(category1) && category2 == selected2) {
//               filtered_list.add(data);
//             } else if (selected1.contains(category1) &&
//                 selected2 == StringClass.ALL) {
//               filtered_list.add(data);
//             } else if (category1 == StringClass.ALL) {
//               filtered_list.add(data);
//             }
//           }
//           return Container(
//               padding: EdgeInsets.only(top: PADDING_TOP + TOP_BAR_HEIGHT),
//               width: MAP_WIDTH,
//               height: MAP_HEIGHT,
//               child: GoogleMap(
//                 polylines: _polyLineList.toSet(),
//                 initialCameraPosition: CAMERA_POSITION_CENTER,
//                 mapToolbarEnabled: false,
//                 markers: createMarker(filtered_list),
//                 mapType: MapType.normal,
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: true,
//                 compassEnabled: false,
//                 onMapCreated: (GoogleMapController controller) {
//                   _controller = controller;
//                 },
//                 zoomControlsEnabled: true,
//                 zoomGesturesEnabled: true,
//                 rotateGesturesEnabled: true,
//                 onTap: (LatLng latLng) {
//                   hideDetail();
//                 },
//               ));
//         }
//         return Container();
//       });
// }

  Marker _currentLocationMarker;

  Set<Marker> createMarker() {
    markers.clear();
    print("createMarker list ${FILTERED_LIST.length}");
    for (int i = 0; i < FILTERED_LIST.length; i++) {
      PlaceData data = FILTERED_LIST[i];
      String title = "[${data.category2}] ${data.name}";
      InfoWindow infoWindow = InfoWindow(title: title);
      Marker marker = Marker(
          markerId: MarkerId(data.docu),
          position: LatLng(data.latitude, data.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: infoWindow,
          onTap: () {
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
          markerId: MarkerId("current"),
          position:
              LatLng(_current_position.latitude, _current_position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(90),
          infoWindow: InfoWindow(title: StringClass.CURRENT_LOCATION),
          onTap: () {});
      markers.add(_currentLocationMarker);
    }

    for (int i = 0; i < NAVI_LIST.length; i++) {
      NaviData n = NAVI_LIST[i];
      for (int j = 0; j < n.coordinates.length; j++) {
        if (n.coordinates != null) {
          Marker m = Marker(
            markerId: MarkerId("navi$i$j"),
            position: LatLng(n.coordinates[j][1], n.coordinates[j][0]),
            icon: BitmapDescriptor.defaultMarkerWithHue(180),
          );
          markers.add(m);
        }
      }
    }
    return markers;
  }

  List<DropdownMenuItem> dropDownMenuRadiusItemList = new List();

  List<DropdownMenuItem> dropDownMenuItemList = new List();
  List<String> dropDownList = new List();
  Set<String> dropDownMenuItemSet = new Set();

  HashMap<String, List<DropdownMenuItem>> dropDownHash = new HashMap();
  HashMap<String, List<String>> dropDownStringHash = new HashMap();

  ProgressDialog _progressDialog;

  @override
  Widget build(BuildContext context) {
    setSize(MediaQuery.of(context));
    appVersionCheck(context);
    initDropDownList();
    print("build isShowingMap $_isShowingMap");
    _progressDialog = new ProgressDialog(
      context,
      message: Text(StringClass.NAVI_LOADING),
    );
    return WillPopScope(
        child: Scaffold(
            body: Stack(children: [
          mapWidget(),
          dropDownView(),
          menuView(),
          _isShowingMap ? Container() : detailView()
        ])),
        onWillPop: () async {
          showExitDialog();
          return false;
        });
  }

  void showExitDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
    var radius = ["전체", "1km", "3km", "5km", "10km"];
    for (int i = 0; i < radius.length; i++) {
      var dropdown = DropdownMenuItem(
          child: Container(
              width: 70,
              child: AutoSizeText(
                radius[i],
                minFontSize: 5,
                style: TextStyle(fontSize: 15),
              )),
          value: dropDownMenuRadiusItemList.length);
      dropDownMenuRadiusItemList.add(dropdown);
    }
  }

  menuView() {
    return Align(
        alignment: Alignment.topRight,
        child: Container(
            margin: EdgeInsets.only(right: 10, left: 10, top: 10 + PADDING_TOP),
            color: Colors.transparent,
            child: PopupMenuButton<int>(
              itemBuilder: (context) => [
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

  void showDetailView(PlaceData data) {
    _currentPlaceData = data;
    print("showDetailView");
    CAMERA_POSITION_CENTER = CameraPosition(
        target: LatLng(_currentPlaceData.latitude, _currentPlaceData.longitude),
        zoom: _zoom);
    setState(() {
      MAP_HEIGHT = SIZE_HEIGHT * 0.65;
      _isShowingMap = false;
      _controller
          .moveCamera(CameraUpdate.newCameraPosition(CAMERA_POSITION_CENTER));
    });
  }

  detailView() {
    print("detailView _isNaviStarted $_isNaviStarted");
    if (_currentPlaceData != null) {
      if (_isNaviStarted) {
        return Align(
            alignment: Alignment.bottomCenter,
            child: Wrap(children: [naviDetailContentView()]));
      } else {
        return Align(
            alignment: Alignment.bottomCenter,
            child: Wrap(
              // shrinkWrap: true,
              // padding: EdgeInsets.only(top: 0),
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                titleView(),
                tabView(),
                bottomView(),
              ],
            ));
      }
    }
    return Container();
  }

  titleView() {
    return Container(
        margin: EdgeInsets.only(top: 0),
        padding: EdgeInsets.only(top: 0),
        alignment: Alignment.topCenter,
        width: SIZE_WIDTH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              minFontSize: 3,
              maxLines: 1,
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            _currentPlaceData.summary.length > 0
                ? AutoSizeText(
                    _currentPlaceData.summary,
                    style: TextStyle(fontSize: 13),
                    minFontSize: 3,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  )
                : Container(),
          ],
        ));
  }

  naviDetailContentView() {
    print("naviDetailContentView $_currentTtsDescription");
    return Container(
      height: NAVI_DETAIL_BOTTOM_HEIGHT,
      padding: EdgeInsets.only(top: 0),
      margin: EdgeInsets.only(top: 0),
      alignment: Alignment.bottomCenter,
      child: Column(
        children: <Widget>[
          AutoSizeText(
            "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
            minFontSize: 6,
            maxFontSize: 15,
            maxLines: 1,
          ),
          _currentTtsDescription.length > 0
              ? AutoSizeText(_currentTtsDescription,
                  minFontSize: 5, maxFontSize: 20, maxLines: 1)
              : Container(),
          Container(
              margin: EdgeInsets.only(top: 10),
              width: SIZE_WIDTH,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                      child: FlatButton(
                    child: AutoSizeText(
                      StringClass.RESTARTED,
                      minFontSize: 6,
                      maxFontSize: getFont(4),
                    ),
                    onPressed: () {
                      _progressDialog.show();
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
                      minFontSize: 6,
                      maxFontSize: getFont(4),
                    ),
                    onPressed: () {
                      _isNaviStarted = false;
                      _controller.hideMarkerInfoWindow(
                          MarkerId(_currentPlaceData.docu));

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
  }

  tabView() {
    return DefaultTabController(
      length: 4,
      child: SizedBox(
        height: SIZE_HEIGHT / 5,
        child: Column(
          children: <Widget>[
            Container(
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
                        minFontSize: 5,
                        maxLines: 1,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_RESTROOM,
                          minFontSize: 5,
                          maxLines: 1,
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_ELEVATOR,
                          maxLines: 1,
                          minFontSize: 5,
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                    Tab(
                      child: AutoSizeText(StringClass.TAB_LABEL_PARKING,
                          maxLines: 1,
                          minFontSize: 5,
                          style: TextStyle(color: Colors.black, fontSize: 12)),
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
    print("getTapImageView path : " + path);
    if (path == null || path.isEmpty) {
      path =
          "https://firebasestorage.googleapis.com/v0/b/nodisable.appspot.com/o/ready.png?alt=media&token=6a6b0cee-e3a3-4354-9ba7-7cfd1d835145";
      return Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: Image.network(path),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              StringClass.READY,
              style: TextStyle(backgroundColor: Colors.white),
            ),
          )
        ],
      );
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

  bottomView() {
    return Container(
        alignment: Alignment.bottomCenter,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/navi.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.NAVI,
                minFontSize: 6,
                maxFontSize: getFont(4),
              ),
            ]),
            onPressed: () {
              print("current location $_current_position");
              fake_index = 0;
              showTtsSelectDialog();
            },
          ),
          FlatButton(
            child: Column(children: [
              Image.asset("asset/images/call.png", width: 20, height: 20),
              AutoSizeText(
                StringClass.CALL,
                minFontSize: 6,
                maxFontSize: getFont(4),
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
                minFontSize: 6,
                maxFontSize: getFont(4),
              ),
            ]),
            onPressed: () {
              _controller
                  .hideMarkerInfoWindow(MarkerId(_currentPlaceData.docu));
              stopNavi();
              hideDetail();
            },
          ),
        ]));
  }

  hideDetail() {
    print("hideDetail");
    if (_polyLineList.length > 0) {
      _polyLineList.clear();
    }
    NAVI_LIST = new List();
    setState(() {
      MAP_HEIGHT = SIZE_HEIGHT;
      _isShowingMap = true;
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
    //
    requestDirection(_current_position.latitude, _current_position.longitude,
            _currentPlaceData.latitude, _currentPlaceData.longitude)
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
            "getOverlay getCurrentLocation  ${_current_position.latitude} ${_current_position.longitude} to ${firstPosition.latitude} ${firstPosition.longitude} bearing $value");

        CAMERA_POSITION_CENTER = CameraPosition(
            target:
                LatLng(_current_position.latitude, _current_position.longitude),
            zoom: _zoom,
            bearing: bearing);
        _lastBearing = bearing;
        _controller
            .moveCamera(CameraUpdate.newCameraPosition(CAMERA_POSITION_CENTER));

        setState(() {});
      });
    });
  }

  dropDownView() {
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
                value: _selectedCategoryRadius,
                items: dropDownMenuRadiusItemList,
                onChanged: (value) {
                  _selectedCategoryRadius = value;
                  updateFilteredList();
                }),
            DropdownButton(
                value: _selectedCategory1,
                items: dropDownMenuItemList,
                onChanged: (value) {
                  _selectedCategory1 = value;
                  _selectedCategory2 = 0;
                  updateFilteredList();
                }),
            DropdownButton(
                value: _selectedCategory2,
                items: dropDownHash[dropDownList[_selectedCategory1]],
                onChanged: (value) {
                  _selectedCategory2 = value;
                  updateFilteredList();
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
  TtsState ttsState = TtsState.stopped;

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
      print(
          "checkDistance top index ${navStackTop.index} distance $distance , $lat , $lon");
      print(
          "checkDistance type ${navStackTop.type} turn type ${navStackTop.turnType}${navStackTop.description}");
      print(
          "checkDistance ttshash contains index ${navStackTop.index} ${ttsHashMap.containsKey(navStackTop.index)} ");

      var ttsForNext = "다음 안내까지 ${distance.toInt()}m";
      showToast(ttsForNext);
      if (_isUsingTTS) {
        _flutterTts.speak(ttsForNext).then((value) {
          if (value == 1) {
            ttsState = TtsState.playing;
          }
        });
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
        if (distance < 20) {
          if (!ttsHashMap.containsKey(navStackTop.index)) {
            if (navStackTop.turnType != null) {
              // text = getTurnTypeText(navStackTop.turnType) + text;
            }
            if (_isUsingTTS) {
              if (text != null &&
                  text.isNotEmpty &&
                  ttsState != TtsState.playing) {
                print("checkDistance play tts $text");
                var ttsRes = await _flutterTts.speak(text);
                if (ttsRes == 1) {
                  ttsState = TtsState.playing;
                  ttsHashMap[navStackTop.index] = text;
                }
              }
            }
          }
          NAVI_DATA_STACK.pop();
          break;
        } else {
          var bearing = Geolocator.bearingBetween(_current_position.latitude,
              _current_position.longitude, lat, lon);
          moveCameraPosition(bearing);
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
    fake_index = 0;
    moveCameraPosition(0);
    MAP_HEIGHT = SIZE_HEIGHT * 0.65;
  }

  void showTtsSelectDialog() async {
    var sdk = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var v = androidInfo.version.release.trim();
      sdk = androidInfo.version.sdkInt;
      print("android version is $v sdk $sdk");
    }
    // distance check
    var distance = Geolocator.distanceBetween(
        _current_position.latitude,
        _current_position.longitude,
        _currentPlaceData.latitude,
        _currentPlaceData.longitude);
    print(
        "distance : $distance , limit max : $NAVI_LIMIT_DISTANCE_MAX , min : $NAVI_LIMIT_DISTANCE_MIN");
    if (NAVI_LIMIT_DISTANCE_MIN <= distance) {
      //TODO
      // if (0 < sdk && sdk < 27) {
      if (sdk < 0) {
        MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
        _progressDialog.show();
        showToast("본 기기는 음성안내를 지원하지 않습니다.");
        _isUsingTTS = false;
        getOverlay(true);
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
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
                          MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
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
                          MAP_HEIGHT = SIZE_HEIGHT - NAVI_DETAIL_BOTTOM_HEIGHT;
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

  getRadiusInt() {
    double radius = 0;
    switch (_selectedCategoryRadius) {
      case 0:
        radius = 0;
        break;
      case 1:
        radius = 1000;
        break;
      case 2:
        radius = 3000;
        break;
      case 3:
        radius = 5000;
        break;
      case 4:
        radius = 10000;
        break;
    }
    return radius;
  }

  void updateFilteredListWithRadius() {
    var tempList = List.from(FILTERED_LIST);
    print(
        "updateFilteredListWithRadius _selectedCategoryRadius $_selectedCategoryRadius radius ${getRadiusInt()} tempList ${tempList.length}");
    for (int i = 0; i < tempList.length; i++) {
      PlaceData d = tempList[i];
      double distance = Geolocator.distanceBetween(_current_position.latitude,
          _current_position.longitude, d.latitude, d.longitude);
      if (getRadiusInt() == 0) {
        continue;
      }
      if (distance > getRadiusInt()) {
        print("updateFilteredListWithRadius remove");
        FILTERED_LIST.removeAt(i);
      }
    }
    print(
        "updateFilteredListWithRadius before ${tempList.length} after ${FILTERED_LIST.length}");
    setState(() {});
  }

  void updateFilteredList() {
    print("updateFilteredList PLACE_LIST ${PLACE_LIST.length}");
    FILTERED_LIST.clear();
    if (_current_position == null) {
      return;
    }
    for (int i = 0; i < PLACE_LIST.length; i++) {
      PlaceData data = PLACE_LIST[i];
      double distance = Geolocator.distanceBetween(_current_position.latitude,
          _current_position.longitude, data.latitude, data.longitude);
      if (getRadiusInt() > 0 && distance > getRadiusInt()) {
        continue;
      }

      String category1 = data.category1;
      String category2 = data.category2;
      String selected1 = dropDownList[_selectedCategory1];
      List<String> subDropDownStringList = dropDownStringHash[selected1];
      String selected2 = subDropDownStringList[_selectedCategory2];
      if (selected1.contains(category1) && category2 == selected2) {
        FILTERED_LIST.add(data);
      } else if (selected1.contains(category1) &&
          selected2 == StringClass.ALL) {
        FILTERED_LIST.add(data);
      } else if (category1 == StringClass.ALL) {
        FILTERED_LIST.add(data);
      }
    }
    print("updateFilteredList FILTERED_LIST ${FILTERED_LIST.length}");
    setState(() {});
  }

  createCircle() {
    print("createCircle _selectedCategoryRadius $_selectedCategoryRadius");
    Set<Circle> circles = Set<Circle>();
    if (_selectedCategoryRadius != 0 && _current_position != null) {
      circles = Set.from([
        Circle(
            circleId: CircleId("current"),
            strokeWidth: 1,
            fillColor: Colors.blue.withOpacity(0.5),
            strokeColor: Colors.blue,
            center:
                LatLng(_current_position.latitude, _current_position.longitude),
            radius: getRadiusInt())
      ]);
    }
    return circles;
  }
}
