import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notifications/notification/bloc/notification_bloc.dart';

import 'notification/view/screen/notification_page.dart';

class HomePage extends StatelessWidget {
  static String routeName = 'home_page_route';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, NotificationPage.routeName);
              })
        ],
      ),
      body: TokenData(),
    );
  }
}

class TokenData extends StatelessWidget {
  const TokenData({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (prev, curr) {
        return (prev != curr) && curr is TokenRecieveSuccess;
      },
      builder: (context, state) {
        if (state is TokenRecieveSuccess) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Token',
                style: TextStyle(fontSize: 18),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  state.token.token,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Text('onTokenRefreshed: ' +
                  (state.token.isRefreshed ? 'yes' : 'no')),
              TextButton(
                  onPressed: () {
                    BlocProvider.of<NotificationBloc>(context)
                        .add(NewTokenRequested());
                  },
                  child: Text('Get New Token'))
            ],
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
