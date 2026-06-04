/// A discriminated union representing either a successful value or a failure.
///
/// Use [Result.success] to wrap a value and [Result.failure] to wrap an
/// error. Check [isSuccess] before accessing [value].
///
/// Example:
/// ```dart
/// final result = await loadData();
/// if (result.isSuccess) {
///   process(result.value!);
/// } else {
///   log(result.error.toString());
/// }
/// ```
class Result<T> {
  const Result._({this.value, this.error});

  final T? value;
  final Object? error;

  /// `true` when this result represents a successful outcome.
  bool get isSuccess => error == null;

  /// Creates a successful [Result] wrapping [value].
  static Result<T> success<T>(T value) => Result<T>._(value: value);

  /// Creates a failed [Result] wrapping [error].
  static Result<T> failure<T>(Object error) => Result<T>._(error: error);
}