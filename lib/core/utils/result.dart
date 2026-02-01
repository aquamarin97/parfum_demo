// result.dart file
class Result<T> {
  const Result._({this.value, this.error});

  final T? value;
  final Object? error;

  bool get isSuccess => error == null;

  static Result<T> success<T>(T value) => Result<T>._(value: value);
  static Result<T> failure<T>(Object error) => Result<T>._(error: error);
}