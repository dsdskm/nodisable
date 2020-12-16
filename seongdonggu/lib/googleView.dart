import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/common/util.dart';
import 'package:seongdonggu/data/dto/categoryData.dart';
import 'package:seongdonggu/data/dto/naviData.dart';
import 'package:seongdonggu/data/dto/placeData.dart';
import 'package:seongdonggu/network/worker.dart';
import 'package:seongdonggu/noticeView.dart';
import 'package:url_launcher/url_launcher.dart';

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

class MainViewState extends State<MainViewWidget> {
  double MAP_WIDTH = SIZE_WIDTH;
  double MAP_HEIGHT = SIZE_HEIGHT;
  final Geolocator _geolocator = Geolocator()..forceAndroidLocationManager;
  Position _current_position;
  int _selectedCategory1 = 0;
  int _selectedCategory2 = 0;
  bool _isShowingMap = true;
  PlaceData _currentPlaceData;
  Timer _timer;
  List<Polyline> _polyLineList = List<Polyline>();
  static double _zoom = 18;
  bool _isNaviStarted = false;
  String _currentTtsDescription = "";
  bool _isUsingTTS = false;

  GoogleMapController _controller;
  CameraPosition CAMERA_POSITION_CENTER = CameraPosition(
    target: LatLng(37.54853, 126.822988),
    zoom: _zoom,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: CURRENT_LOCATION_CHECK_DELAY),
        (timer) {
      getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
  }

  getCurrentLocation() async {
    print("getCurrentLocation by timer");
    _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      print("getCurrentLocation position $position");
      setState(() {
        if (DEBUG) {
          _current_position = getFakePosition();
        } else {
          _current_position = position;
        }
        print("update current position $_current_position");
        checkDistance();
        setState(() {});
      });
    }).catchError((e) {
      print(e);
    });
  }

  Set<Marker> markers = new Set();

  Widget mapWidget() {
    return FutureBuilder(
        future: DATABASE.placeDao.getAllPlace(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            markers.clear();
            List<PlaceData> list = snapshot.data;
            List<PlaceData> filtered_list = List();
            for (int i = 0; i < list.length; i++) {
              PlaceData data = list[i];
              String category1 = data.category1;
              String category2 = data.category2;
              String selected1 = dropDownList[_selectedCategory1];
              List<String> subDropDownStringList =
                  dropDownStringHash[selected1];
              String selected2 = subDropDownStringList[_selectedCategory2];
              if (category1 == selected1 && category2 == selected2) {
                filtered_list.add(data);
              } else if (selected2 == StringClass.ALL) {
                filtered_list.add(data);
              }
            }
            return Container(
                padding: EdgeInsets.only(top: PADDING_TOP + TOP_BAR_HEIGHT),
                width: MAP_WIDTH,
                height: MAP_HEIGHT,
                child: GoogleMap(
                  polylines: _polyLineList.toSet(),
                  initialCameraPosition: CAMERA_POSITION_CENTER,
                  mapToolbarEnabled: false,
                  markers: createMarker(filtered_list),
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  onTap: (LatLng latLng) {
                    hideDetail();
                  },
                ));
          }
          return Container();
        });
  }

  Set<Marker> createMarker(List<PlaceData> list) {
    print("createMarker");
    for (int i = 0; i < list.length; i++) {
      PlaceData data = list[i];
      String title = "[${data.category2}] ${data.name}";
      Marker marker = Marker(
          markerId: MarkerId(data.docu),
          position: LatLng(data.latitude, data.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: title),
          onTap: () {
            showDetailView(data);
          });
      markers.add(marker);
    }

    if (DEBUG) {
      if (_current_position != null) {
        Marker marker = Marker(
            markerId: MarkerId("current"),
            position:
                LatLng(_current_position.latitude, _current_position.longitude),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: StringClass.CURRENT_LOCATION),
            onTap: () {});
        markers.add(marker);
      }
    }
    return markers;
  }

  List<DropdownMenuItem> dropDownMenuItemList = new List();
  List<String> dropDownList = new List();
  Set<String> dropDownMenuItemSet = new Set();

  HashMap<String, List<DropdownMenuItem>> dropDownHash = new HashMap();
  HashMap<String, List<String>> dropDownStringHash = new HashMap();

  @override
  Widget build(BuildContext context) {
    initDropDownList();
    print("build isShowingMap $_isShowingMap");
    return Scaffold(
        body: Stack(children: [
      mapWidget(),
      dropDownView(),
      menuView(),
      _isShowingMap ? Container() : detailView()
    ]));
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
                child: Text(
              data.value,
              style: TextStyle(fontSize: 20),
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
                child: Text(
              data.value,
              style: TextStyle(fontSize: 20),
            )),
            value: data.index);
        dropDownHash[data.category].add(submenuItem);
        dropDownStringHash[data.category].add(data.value);
        index++;
      }
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
                PopupMenuItem(value: 0, child: Text(StringClass.NOTICE)),
                PopupMenuItem(value: 1, child: Text(StringClass.REVIEW)),
                PopupMenuItem(value: 2, child: Text(StringClass.EXIT)),
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
        goInAppReview();
        break;
      case 2:
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        break;
      case 3:
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
      MAP_HEIGHT = SIZE_HEIGHT / 2;
      _isShowingMap = false;
      _controller
          .moveCamera(CameraUpdate.newCameraPosition(CAMERA_POSITION_CENTER));
    });
  }

  detailView() {
    print(
        "detailView width ${SIZE_WIDTH / 1.5} , _isNaviStarted $_isNaviStarted");
    if (_currentPlaceData != null) {
      if (_isNaviStarted) {
        return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [naviDetailContentView()])));
      } else {
        return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleView(),
                    Padding(padding: EdgeInsets.all(5)),
                    tabView(),
                    bottomView(),
                  ],
                )));
      }
    }
    return Container();
  }

  titleView() {
    return Container(
        padding: EdgeInsets.only(top: 10),
        color: Colors.transparent,
        width: SIZE_WIDTH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.start,
            ),
            Text(
              _currentPlaceData.summary,
              style: TextStyle(fontSize: 17),
              textAlign: TextAlign.start,
            ),
          ],
        ));
  }

  naviDetailContentView() {
    print("naviDetailContentView $_currentTtsDescription");
    bool isArrived = _currentTtsDescription == StringClass.ARRIVE;
    return Container(
      alignment: Alignment.bottomCenter,
      child: Column(
        children: <Widget>[
          Text("[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              style: TextStyle(fontSize: 20)),
          Text(_currentTtsDescription, style: TextStyle(fontSize: 25)),
          Container(
            width: SIZE_WIDTH / 2,
            height: SIZE_WIDTH / 2,
            child: getTapImageView(_currentPlaceData.image_base),
          ),
          Container(
              width: SIZE_WIDTH,
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  !isArrived
                      ? Container(
                          child: FlatButton(
                          child: Text(
                            StringClass.RESTARTED,
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            getOverlay();
                            if (_isUsingTTS) {
                              flutterTts.speak(StringClass.TTS_RESTARTED);
                            }
                          },
                        ))
                      : Container(
                          child: FlatButton(
                            child: Text(
                              StringClass.ARRIVE,
                              style: TextStyle(fontSize: 20),
                            ),
                            onPressed: () {
                              _currentTtsDescription = "";
                              _isNaviStarted = false;
                              showDetailView(_currentPlaceData);
                            },
                          ),
                        ),
                  !isArrived
                      ? Container(
                          child: FlatButton(
                          child: Text(
                            StringClass.CANCEL,
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            _isNaviStarted = false;
                            hideDetail();
                            if (_isUsingTTS) {
                              stopNavi();
                              flutterTts.speak(StringClass.TTS_CANCELED);
                            }
                          },
                        ))
                      : Container()
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
        height: SIZE_HEIGHT / 3,
        child: Column(
          children: <Widget>[
            Container(
                padding: EdgeInsets.all(7),
                child: TabBar(
                  indicatorColor: Colors.blue,
                  indicatorWeight: 1,
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
                      child: Text(
                        StringClass.TAB_LABEL_GYUNGSARO,
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ),
                    Tab(
                      child: Text(StringClass.TAB_LABEL_RESTROOM,
                          style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                    Tab(
                      child: Text(StringClass.TAB_LABEL_ELEVATOR,
                          style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                    Tab(
                      child: Text(StringClass.TAB_LABEL_PARKING,
                          style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                  ],
                )),
            Padding(padding: EdgeInsets.all(5)),
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
            Padding(padding: EdgeInsets.all(5)),
          ],
        ),
      ),
    );
  }

  getTapImageView(String path) {
    if (path == null || path.isEmpty) {
      path = _currentPlaceData.image_base;
    }
    return Container(
      child: Image.network(path),
    );
  }

  bottomView() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            alignment: Alignment.bottomCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatButton(
                    child: Column(children: [
                      Image.asset("asset/images/navi.png",
                          width: 30, height: 30),
                      Text(StringClass.NAVI),
                    ]),
                    onPressed: () {
                      print("current location $_current_position");
                      _isNaviStarted = true;
                      showTtsSelectDialog();
                    },
                  ),
                  FlatButton(
                    child: Column(children: [
                      Image.asset("asset/images/call.png",
                          width: 30, height: 30),
                      Text(StringClass.CALL),
                    ]),
                    onPressed: () {
                      print("current location $_current_position");
                      launch(('tel://${_currentPlaceData.contact}'));
                    },
                  ),
                  FlatButton(
                    child: Column(children: [
                      Image.asset("asset/images/cancel.png",
                          width: 30, height: 30),
                      Text(StringClass.CANCEL),
                    ]),
                    onPressed: () {
                      hideDetail();
                    },
                  ),
                ])));
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

  void getOverlay() async {
    print("getOverlay");
    _polyLineList.clear();
    _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        if (DEBUG) {
          _current_position = getFakePosition();
        } else {
          _current_position = position;
        }

        requestDirection3(
                _current_position.latitude,
                _current_position.longitude,
                _currentPlaceData.latitude,
                _currentPlaceData.longitude)
            .then((value) {
          _polyLineList = value;
          setState(() {
            CAMERA_POSITION_CENTER = CameraPosition(
                target: LatLng(
                    _current_position.latitude, _current_position.longitude),
                zoom: _zoom);
            _controller.moveCamera(
                CameraUpdate.newCameraPosition(CAMERA_POSITION_CENTER));
            checkDistance();
          });
        });
      });
    }).catchError((e) {
      print(e);
    });
  }

  dropDownView() {
    return Container(
        height: TOP_BAR_HEIGHT,
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(right: 10, left: 10, top: PADDING_TOP),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            DropdownButton(
                value: _selectedCategory1,
                items: dropDownMenuItemList,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory1 = value;
                    _selectedCategory2 = 0;
                  });
                }),
            DropdownButton(
                value: _selectedCategory2,
                items: dropDownHash[dropDownList[_selectedCategory1]],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory2 = value;
                  });
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
  FlutterTts flutterTts = FlutterTts();

  void checkDistance() async {
    // tts check
    if ( NAVI_LIST != null) {
      List<NaviData> naviListForTTS = new List();
      for (int i = 0; i < NAVI_LIST.length; i++) {
        NaviData nv = NAVI_LIST[i];
        String name = nv.name;
        String description = nv.description;
        int turnType = nv.turnType;
        String pointType = nv.pointType;
        print("checkDistance description $description");
        for (int j = 0; j < nv.coordinates.length; j++) {
          LatLng latlng =
              new LatLng(nv.coordinates[j][1], nv.coordinates[j][0]);
          double distance = await _geolocator.distanceBetween(
              _current_position.latitude,
              _current_position.longitude,
              latlng.latitude,
              latlng.longitude);
          print("checkDistance distance for nav $distance");
          if (distance < 20) {
            naviListForTTS.add(nv);
          }
        }
      }
      // tts play
      print("naviListForTTS ${naviListForTTS.length} ttsHash $ttsHash}");
      if (_isUsingTTS) {
        if (ttsHash.length == 0) {
          ttsHash[StringClass.TTS_STARTED] = StringClass.TTS_STARTED;
          await flutterTts.speak(StringClass.TTS_STARTED);
          return;
        } else {
          await flutterTts.speak("");
        }

        await flutterTts.awaitSpeakCompletion(true);
        flutterTts.setCompletionHandler(() async {
          for (int i = 0; i < naviListForTTS.length; i++) {
            NaviData nv = naviListForTTS[i];
            if (ttsHash.containsKey(nv.description)) {
              continue;
            }
            _currentTtsDescription = nv.description;
            String tts = nv.description;
            if (nv.description == StringClass.ARRIVE) {
              naviListForTTS.clear();
              stopNavi();
              tts = StringClass.TTS_ARRIVED;
              showToast(StringClass.TTS_ARRIVED);
            }
            if (_isUsingTTS) {
              print("tts $tts");
              await flutterTts.speak(tts);
              flutterTts.setCompletionHandler(() {
                ttsHash[nv.description] = nv.description;
              });
            }
          }
        });
      }
      setState(() {});
    }
  }

  void stopNavi() {
    print("stopNavi");
    NAVI_LIST.clear();
    _polyLineList.clear();
    _isNaviStarted = false;
    ttsHash.clear();
    fake_index = 0;
  }

  final InAppReview inAppReview = InAppReview.instance;

  Future<void> goInAppReview() async {
    if (await inAppReview.isAvailable()) {
      print("goInAppReview isAvailable");
      inAppReview.requestReview();
    } else {
      print("goInAppReview isNotAvailable");
      //inAppReview.openStoreListing(appStoreId: '<YOUR_APP_STORE_ID>')
    }
  }

  void showTtsSelectDialog() {
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
                    getOverlay();
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  },
                ),
                new FlatButton(
                  child: new Text(StringClass.NO),
                  onPressed: () {
                    _isUsingTTS = false;
                    getOverlay();
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  },
                ),
              ],
            ));
  }
}
