import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:seongdonggu/common/cahced.dart';
import 'package:seongdonggu/common/constants.dart';
import 'package:seongdonggu/common/stringConstant.dart';
import 'package:seongdonggu/data/dto/noticeData.dart';
import 'package:seongdonggu/noticeDetailView.dart';

class InAppReviewWidget extends StatelessWidget {
  static String route = "/inAppReview";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: <String, WidgetBuilder>{
      route: (BuildContext context) => AppReviewWidget()
    }, home: AppReviewWidget());
  }
}

class AppReviewWidget extends StatefulWidget {
  @override
  AppReviewState createState() => AppReviewState();
}

class AppReviewState extends State<AppReviewWidget> {
  final InAppReview _inAppReview = InAppReview.instance;
  String _appStoreId = '';
  String _microsoftStoreId = '';
  bool _isAvailable;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inAppReview
          .isAvailable()
          .then(
            (bool isAvailable) => setState(
              () => _isAvailable = isAvailable && !Platform.isAndroid,
        ),
      )
          .catchError((_) => setState(() => _isAvailable = false));
    });
  }

  void _setAppStoreId(String id) => _appStoreId = id;

  void _setMicrosoftStoreId(String id) => _microsoftStoreId = id;

  Future<void> _requestReview() => _inAppReview.requestReview();

  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
    appStoreId: _appStoreId,
    microsoftStoreId: _microsoftStoreId,
  );

  @override
  Widget build(BuildContext context) {
    const loadingMessage = 'LOADING';
    const availableMessage = 'AVAILABLE';
    const unavailableMessage = 'UNAVAILABLE';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('InAppReview Example')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'InAppReview status: ${_isAvailable == null ? loadingMessage : _isAvailable ? availableMessage : unavailableMessage}',
            ),
            TextField(
              onChanged: _setAppStoreId,
              decoration: InputDecoration(hintText: 'App Store ID'),
            ),
            TextField(
              onChanged: _setMicrosoftStoreId,
              decoration: InputDecoration(hintText: 'Microsoft Store ID'),
            ),
            RaisedButton(
              onPressed: _requestReview,
              child: Text('Request Review'),
            ),
            RaisedButton(
              onPressed: _openStoreListing,
              child: Text('Open Store Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
