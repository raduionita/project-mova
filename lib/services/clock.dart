/// Time source. Production uses [SystemClock]; tests use [FakeClock].
abstract class Clock {
  DateTime now();
}

/// Wall-clock implementation backed by `DateTime.now`.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Controllable clock for tests.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) {
    _now = value;
  }

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
