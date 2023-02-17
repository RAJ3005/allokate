import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'database.dart';

//https://pub.dev/packages/flutter_local_notifications/example
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<String> getToken() async {
    String token = await _firebaseMessaging.getToken();
    return token;
  }

  Future<void> init() async {
    if (!_initialized) {
      // For iOS request permission first.
      _firebaseMessaging.requestPermission(alert: true);

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();

      firebaseMessaging.subscribeToTopic('everyone');

      DatabaseService().updateMessagingToken(token);

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage message) {
        if (message != null) {}
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification notification = message.notification;
        AndroidNotification android = message.notification?.android;
        AndroidNotificationChannel channel = const AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description: 'This channel is used for important notifications.', // description
          importance: Importance.high,
        );

        if (notification != null && android != null) {
          _flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  // TODO add a proper drawable resource to android, for now using
                  //      one that already exists in example app.
                  icon: 'launch_background',
                ),
              ));
        }
      });
      _initialized = true;
    }
  }

  // Replace with server token from firebase console settings.
  final String serverToken =
      'AAAAQEj7BhA:APA91bE_-VhWwaje3moRBJHqaWmjJ_EqTrgorsM7uwwyd9RQyLIqn1G45erZ_147XETp__ZuPyGgmm6SUla_D8XVnFZb13mFvQe4IQCJezlwvPjCpgkJ5xchfTT6XjqIU1el6bqcHbFy';
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<void> sendMessage({String to, String title, String message}) async {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{'body': message, 'title': title},
          'priority': 'high',
          'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'id': '1', 'status': 'done'},
          'to':
              'ezULGRWF2UmYixRVujCla6:APA91bG5pa7nuKTdiqlI5JzX5PZdq57znTlD4G9F37R2fPlmoxsURCezNiYMPfSdQTiWX-zbfE2ocW_0ZAG-d_lw8a7JV_hmQfjU01GLDrklGFfhibU6EpIBe50rxVAkCLJfdKQQHLbE',
        },
      ),
    );
  }
}
