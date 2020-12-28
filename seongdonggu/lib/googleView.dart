import 'dart:async';
import 'dart:collection';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ndialog/ndialog.dart';

// import 'package:progress_dialog/progress_dialog.dart';
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
  static double _zoom = 15;
  bool _isNaviStarted = false;
  String _currentTtsDescription = "";
  bool _isUsingTTS = false;

  GoogleMapController _controller;
  CameraPosition CAMERA_POSITION_CENTER = CameraPosition(
    target: LatLng(37.56293282386673, 127.03693424203551),
    zoom: _zoom,
  );

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _timer = Timer.periodic(Duration(seconds: CURRENT_LOCATION_CHECK_DELAY),
        (timer) {
      getCurrentLocation();
    });
  }

  @override
  void dispose() {
    print("dispose");
    _timer.cancel();
  }

  getCurrentLocation() async {
    print("getCurrentLocation by timer");
    _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        print(
            "DEBUG $DEBUG _isNaviStarted $_isNaviStarted getCurrentLocation position $position");
        if (DEBUG && _isNaviStarted) {
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
              if (selected1.contains(category1) && category2 == selected2) {
                filtered_list.add(data);
              } else if (selected1.contains(category1) &&
                  selected2 == StringClass.ALL) {
                filtered_list.add(data);
              } else if (category1 == StringClass.ALL) {
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

  Marker _currentLocationMarker;

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

    if (_current_position != null) {
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
    return markers;
  }

  List<DropdownMenuItem> dropDownMenuItemList = new List();
  List<String> dropDownList = new List();
  Set<String> dropDownMenuItemSet = new Set();

  HashMap<String, List<DropdownMenuItem>> dropDownHash = new HashMap();
  HashMap<String, List<String>> dropDownStringHash = new HashMap();

  ProgressDialog _progressDialog;

  @override
  Widget build(BuildContext context) {
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
                width: 80,
                child: AutoSizeText(
                  data.value,
                  minFontSize: 7,
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
                width: 80,
                child: AutoSizeText(
                  data.value,
                  minFontSize: 7,
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
        return Container(
            constraints: BoxConstraints.expand(),
            margin: EdgeInsets.only(top: MAP_HEIGHT),
            height: SIZE_HEIGHT,
            alignment: Alignment.bottomCenter,
            child: ListView(children: [naviDetailContentView()]));
      } else {
        return Container(
            constraints: BoxConstraints.expand(),
            margin: EdgeInsets.only(top: MAP_HEIGHT),
            height: SIZE_HEIGHT,
            alignment: Alignment.bottomCenter,
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                titleView(),
                Padding(padding: EdgeInsets.all(5)),
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
        padding: EdgeInsets.only(top: 10),
        color: Colors.transparent,
        width: SIZE_WIDTH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              minFontSize: 3,
              maxLines: 1,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            _currentPlaceData.summary.length > 0
                ? AutoSizeText(
                    _currentPlaceData.summary,
                    style: TextStyle(fontSize: 17),
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
      alignment: Alignment.bottomCenter,
      child: Column(
        children: <Widget>[
          AutoSizeText(
              "[${_currentPlaceData.category2}]${_currentPlaceData.name}",
              minFontSize: 5,
              maxLines: 1,
              style: TextStyle(fontSize: 20)),
          _currentTtsDescription.length > 0
              ? AutoSizeText(_currentTtsDescription,
                  minFontSize: 5, maxLines: 1, style: TextStyle(fontSize: 25))
              : Container(),
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
                  Container(
                      child: FlatButton(
                    child: AutoSizeText(
                      StringClass.RESTARTED,
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      _progressDialog.show();
                      getOverlay(true);
                      if (_isUsingTTS) {
                        flutterTts.speak(StringClass.TTS_RESTARTED);
                      }
                    },
                  )),
                  Container(
                      child: FlatButton(
                    child: AutoSizeText(
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
                padding: EdgeInsets.all(3),
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
        child: Image.network(path),
      );
    }
  }

  bottomView() {
    return Expanded(
        child: Container(
            alignment: Alignment.bottomCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatButton(
                    child: Column(children: [
                      Image.asset("asset/images/navi.png",
                          width: 30, height: 30),
                      AutoSizeText(StringClass.NAVI),
                    ]),
                    onPressed: () {
                      print("current location $_current_position");
                      fake_index = 0;
                      showTtsSelectDialog();
                    },
                  ),
                  FlatButton(
                    child: Column(children: [
                      Image.asset("asset/images/call.png",
                          width: 30, height: 30),
                      AutoSizeText(StringClass.CALL),
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
                      AutoSizeText(StringClass.CANCEL),
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

  void getOverlay(bool start) async {
    print("getOverlay");

    _polyLineList.clear();
    _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      _progressDialog.dismiss();
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
            _progressDialog.dismiss();
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
        margin: EdgeInsets.only(right: 20, left: 20, top: PADDING_TOP),
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
    _progressDialog.dismiss();
    // tts check
    if (NAVI_LIST != null) {
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
          if (distance < NAVI_LIST_DISTANCE) {
            naviListForTTS.add(nv);
          }
        }
      }
      // tts play
      print("naviListForTTS ${naviListForTTS.length} ttsHash $ttsHash}");
      if (_isUsingTTS && _isNaviStarted) {
        String text = "";
        if (ttsHash.length == 0) {
          ttsHash[StringClass.TTS_STARTED] = StringClass.TTS_STARTED;
          text = StringClass.TTS_STARTED;
        } else {
          text = StringClass.TTS_VOID;
        }
        print("tts text $text");
        await flutterTts.speak(text).then((value) => {
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
                    await flutterTts.speak(tts);
                    showToast(StringClass.TTS_ARRIVED);
                    setState(() {});
                    return;
                  }
                  if (_isUsingTTS && _isNaviStarted) {
                    print("tts text $tts");
                    await flutterTts.speak(tts);
                    flutterTts.setCompletionHandler(() {
                      ttsHash[nv.description] = nv.description.trim();
                    });
                  }
                }
              })
            });
        // flutterTts.awaitSpeakCompletion(true);

      }
      setState(() {});
    } else {
      await flutterTts.speak(StringClass.TTS_ARRIVED);
      showToast(StringClass.TTS_ARRIVED);
      setState(() {});
      return;
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
    inAppReview.openStoreListing();
  }

  void showTtsSelectDialog() {
    // distance check
    _geolocator
        .distanceBetween(
            _current_position.latitude,
            _current_position.longitude,
            _currentPlaceData.latitude,
            _currentPlaceData.longitude)
        .then((value) {
      print(
          "distance : $value , limit max : $NAVI_LIMIT_DISTANCE_MAX , min : $NAVI_LIMIT_DISTANCE_MIN");
      if (NAVI_LIMIT_DISTANCE_MIN <= value &&
          value <= NAVI_LIMIT_DISTANCE_MAX) {
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
                        _isNaviStarted = true;
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        _progressDialog.show();
                        getOverlay(true);
                      },
                    ),
                    new FlatButton(
                      child: new Text(StringClass.NO),
                      onPressed: () {
                        _isUsingTTS = false;
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        getOverlay(true);
                      },
                    ),
                  ],
                ));
      } else {
        Fluttertoast.showToast(
            msg: StringClass.NAVI_ERR_MSG,
            backgroundColor: Colors.lightBlue,
            gravity: ToastGravity.CENTER);
      }
    });
  }
}
