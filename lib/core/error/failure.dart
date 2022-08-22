import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});
  @override
  List<Object> get props => [message, statusCode ?? 400];
}

class LocalFailure extends Failure {
  const LocalFailure(String message) : super(message);
}
