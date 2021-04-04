import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'entities/notification_entity.dart';
import 'notification_repository.dart';

const AndroidNotificationChannel _androidNotificationChannel =
    AndroidNotificationChannel(
        'high_importance_channel',
        'Important Notifications',
        'This channel if for important notifications',
        importance: Importance.max);

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // TODO: implement local storage
}

class NotificationRepositoryFCM implements NotificationRepository {
  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late final FirebaseMessaging _firebaseMessaging;

  final _streamController = StreamController<NotificationEntity>();

  @override
  Stream<NotificationEntity> get notificationStream async* {
    yield* _streamController.stream;
  }

  @override
  void dispose() {
    _streamController.close();
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    String? token = await FirebaseMessaging.instance.getToken();
    print(token);
    _setupOnMessageListener();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _handleInteraction();
    if (Platform.isAndroid)
      await _enableAndroidForegroundNotification();
    else if (Platform.isIOS) await _enableIOSForegroundNotification();
  }

  Future<void> scheduleNotification(RemoteMessage remoteMessage) async {
    RemoteNotification? remoteNotification = remoteMessage.notification;
    if (Platform.isAndroid &&
        (remoteNotification != null) &&
        (remoteNotification.android != null)) {
      _flutterLocalNotificationsPlugin.show(
          remoteMessage.messageId.hashCode,
          remoteNotification.title,
          remoteNotification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
                _androidNotificationChannel.id,
                _androidNotificationChannel.name,
                _androidNotificationChannel.description,
                icon: 'launch_background',
                importance: Importance.max),
          ));
    }
  }

  Future _enableAndroidForegroundNotification() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidNotificationChannel);
  }

  Future _enableIOSForegroundNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future _handleInteraction() async {
    RemoteMessage? interactedMessage =
        await _firebaseMessaging.getInitialMessage();
    if (interactedMessage != null) {
      RemoteNotification? remoteNotification = interactedMessage.notification;
      if (remoteNotification != null) {
        NotificationEntity notificationEntity = NotificationEntity(
            body: remoteNotification.body ?? '',
            title: remoteNotification.title ?? '',
            id: interactedMessage.messageId.hashCode,
            hasInteracted: true);
        _streamController.add(notificationEntity);
      }
      print('interacted message opened from terminated');
    }
    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage interactedMessage) {
      RemoteNotification? remoteNotification = interactedMessage.notification;
      if (remoteNotification != null) {
        NotificationEntity notificationEntity = NotificationEntity(
            body: remoteNotification.body ?? '',
            title: remoteNotification.title ?? '',
            id: interactedMessage.messageId.hashCode,
            hasInteracted: true);
        _streamController.add(notificationEntity);
      }
      print('interacted message opened from background');
    });
  }

  void _setupOnMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      scheduleNotification(remoteMessage);
      _streamController
          .add(NotificationEntity.fromRemoteMessage(remoteMessage));
    });
  }
}
