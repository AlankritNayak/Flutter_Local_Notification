import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_notifications/notification/models/notification.dart';
import 'package:notification_repository/notification_repository.dart';
import 'package:pedantic/pedantic.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// A Bloc that listens to [NotificationRepository]'s notificationStream, and add a [NotificationReceived] event
/// in response to new notification received.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  late StreamSubscription<NotificationEntity> _notificationSubscription;
  late StreamSubscription<Token> _tokenSubscription;
  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationInitial()) {
    _notificationSubscription = _notificationRepository.notificationStream
        .listen((NotificationEntity notificationEntity) {
      add(NotificationReceived(notificationEntity));
    });
    _tokenSubscription = _notificationRepository.tokenStream.listen((token) {
      add(TokenReceived(token));
    });
  }
  @override
  Future<void> close() {
    _notificationRepository.dispose();
    _notificationSubscription.cancel();
    return super.close();
  }

  @override
  Stream<NotificationState> mapEventToState(
    NotificationEvent event,
  ) async* {
    if (event is NotificationReceived) {
      yield await _mapNotificationReceivedToState(event);
    }
    if (event is TokenReceived) {
      yield await _mapTokenReceivedToState(event);
    }
    if (event is NewTokenRequested) {
      yield await _mapTokenRequestedToState(event);
    }
  }

  Future<NotificationState> _mapTokenRequestedToState(
      NewTokenRequested event) async {
    unawaited(_notificationRepository.getNewToken());
    return state;
  }

  Future<NotificationState> _mapNotificationReceivedToState(
      NotificationReceived event) async {
    final notificationEntity = event.notificationEntity;
    return NotificationRecieveSuccess(
        NotificationModel.fromEntity(notificationEntity));
  }

  Future<NotificationState> _mapTokenReceivedToState(
      TokenReceived event) async {
    final token = event.token;
    return TokenRecieveSuccess(token);
  }
}
