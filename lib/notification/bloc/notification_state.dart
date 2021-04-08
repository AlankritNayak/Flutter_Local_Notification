part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationRecieveSuccess extends NotificationState {
  NotificationRecieveSuccess(this.notificationModel);
  final NotificationModel notificationModel;
  @override
  List<Object> get props => [notificationModel];
}

class TokenRecieveSuccess extends NotificationState {
  TokenRecieveSuccess(this.token);
  final Token token;
  @override
    List<Object> get props => [token];
}

