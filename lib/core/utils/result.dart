import 'package:notes_app/core/errors/failures.dart';

/// A generic result class to handle success or failure from operations
class Result<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  Result._({this.data, this.failure, required this.isSuccess});

  /// Creates a success result with data
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// Creates a failure result with error message
  factory Result.failure(Failure failure) {
    return Result._(failure: failure, isSuccess: false);
  }
}
