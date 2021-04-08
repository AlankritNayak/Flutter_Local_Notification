import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_repository/notification_repository.dart';

import 'entities/notification_entity.dart';
import 'notification_repository.dart';

/// On Android each notification is assigned to a Notification Channel  determine how the notification is displayed.
/// the default notification channel for [FirebaseMessaging] is of Low importance, so, it does not show Heads up notifications.
/// In order to overcome this, we are creating a new [AndroidNotificationChannel], which if of [Importance.max]
const AndroidNotificationChannel _androidNotificationChannel =
    AndroidNotificationChannel(
        'high_importance_channel',
        'Important Notifications',
        'This channel if for important notifications',
        importance: Importance.max);

/// This is the [BackgroundMessageHandler] that will be called when a notification is received, when the app is in
/// background or terminated state. This is a top level function, outside of any class, and will run outside of app's
/// context, we cannot do any UI implementing logic here. that is we cannot add new notification to the [NotificationRepository.notificationStream],
/// in this handler.
Future<void> firebaseMessagingBackgroundHandlerLocal(
    RemoteMessage remoteMessage) async {
  print("Handling a background message: ${remoteMessage.messageId}");
  // TODO: Implement storing the notification to local storage

  if (remoteMessage.data['read'] == 'true') {
    print('inside cancel');
    await FlutterLocalNotificationsPlugin().cancelAll();
    return;
  }
  final Map<String, dynamic>? data = remoteMessage.data;
      if (data != null) {
      FlutterLocalNotificationsPlugin().show(
          remoteMessage.messageId.hashCode,
          data['title'],
          data['body'],
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

///This is the FCM specific implementation for the [NotificationRepository]
/// FCM directly handles showing notification when the app is in background or terminated, however,
/// for showing notifications when the app is in foreground, we are delegating this task to
/// [FlutterLocalNotificationsPlugin].
class NotificationRepositoryLocal implements NotificationRepository {
  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late final FirebaseMessaging _firebaseMessaging;

  final _notificationStreamController = StreamController<NotificationEntity>();
  final _tokenStreamController = StreamController<Token>();

  @override
  Stream<NotificationEntity> get notificationStream async* {
    yield* _notificationStreamController.stream;
  }

  @override
  Stream<Token> get tokenStream async* {
    yield* _tokenStreamController.stream;
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    _tokenStreamController.close();
  }

  @override
  Future getNewToken() async {
    final token = await _firebaseMessaging.getToken();
    _tokenStreamController.add(Token(token!, false));
    print('getNewToken: $token');
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    await _setTokenListener();
    _setupOnMessageListener();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandlerLocal);
    await _handleInteraction();
    if (Platform.isAndroid)
      await _enableAndroidForegroundNotification();
    else if (Platform.isIOS) await _enableIOSForegroundNotification();
  }

  /// schedules a notification, using [FlutterLocalNotificationsPlugin]
  Future<void> scheduleNotification(RemoteMessage remoteMessage) async {
    final Map<String, dynamic>? data = remoteMessage.data;
    if (data != null) {
      FlutterLocalNotificationsPlugin().show(
          remoteMessage.messageId.hashCode,
          data['title'],
          data['body'],
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

  /// Adds [_androidNotificationChannel] as a new [AndroidNotificationChannel]
  Future _enableAndroidForegroundNotification() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidNotificationChannel);
  }

  /// Enables foreground notifiation for IOS, we do NOT need [FlutterLocalNotificationsPlugin] to show foreground
  /// notifications for IOS.
  Future _enableIOSForegroundNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Checks if the app is opened as a result of User tapping the notification, if so,
  /// it adds the tapped notification to the [notificationStream]
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
        _notificationStreamController.add(notificationEntity);
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
        _notificationStreamController.add(notificationEntity);
      }
      print('interacted message opened from background');
    });
  }

  Future _setTokenListener() async {
    String? token = await _firebaseMessaging.getToken();
    print('on getToken: $token');
    _tokenStreamController.add(Token(token!, false));
    _firebaseMessaging.onTokenRefresh.listen((token) {
      print('on Token Refresh: $token');
      _tokenStreamController.add(Token(token, true));
    });
  }

  /// Sets up a [FirebaseMessaging.onMessage] listener, which will emit new notification when the
  /// app is in foreground
  void _setupOnMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      scheduleNotification(remoteMessage);
      _notificationStreamController
          .add(NotificationEntity.fromRemoteMessage(remoteMessage));
    });
  }
}
