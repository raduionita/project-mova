/// Outcome of a domain operation that can fail without throwing.
class Result<T> {
  const Result.ok(this.value) : message = null;

  const Result.failure(this.message) : value = null;

  final T? value;
  final String? message;

  bool get isOk => message == null;

  bool get isFailure => !isOk;
}
