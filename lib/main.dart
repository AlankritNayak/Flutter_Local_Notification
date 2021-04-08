import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notifications/notification/bloc/notification_bloc.dart';
import 'package:flutter_notifications/notification/view/screen/notification_page.dart';
import 'package:notification_repository/notification_repository.dart';

import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationRepositoryLocal notificationRepositoryLocal =
      NotificationRepositoryLocal();
  await notificationRepositoryLocal.initialize();
  runApp(MyApp(
    notificationRepository: notificationRepositoryLocal,
  ));
}

class MyApp extends StatefulWidget {
  MyApp({Key? key, required this.notificationRepository}) : super(key: key);

  final NotificationRepository notificationRepository;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigator => _navigatorKey.currentState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>(
      create: (context) =>
          NotificationBloc(notificationRepository: widget.notificationRepository),
      child: MaterialApp(
        title: 'Flutter Demo',
        builder: (context, child) {
          return BlocListener<NotificationBloc, NotificationState>(
            listener: (context, state) {
              if (state is NotificationRecieveSuccess &&
                  state.notificationModel.hasInteracted) {
                _navigator?.pushNamed(NotificationPage.routeName);
              }
            },
            child: child,
          );
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          '/': (context) => HomePage(),
          NotificationPage.routeName: (context) => NotificationPage()
        },
      ),
    );
  }
}
