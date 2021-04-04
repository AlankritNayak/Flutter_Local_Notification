import 'dart:async';
import 'entities/entities.dart';

abstract class NotificationRepository {
  Future<void> initialize();
  Stream<NotificationEntity> get notificationStream;
  void dispose();
}
