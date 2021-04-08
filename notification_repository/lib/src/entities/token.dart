import 'package:equatable/equatable.dart';

class Token extends Equatable {
  final String token;
  final bool isRefreshed;

  Token(this.token, this.isRefreshed);

  @override
  List<Object?> get props => [token, isRefreshed];
}
