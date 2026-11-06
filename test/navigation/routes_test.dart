import 'package:flutter_test/flutter_test.dart';
import 'package:mova/navigation/routes.dart';

void main() {
  test('exercise detail routes round trip the exercise id', () {
    expect(
      Routes.exerciseDetail('barbell-bench-press'),
      '/train/exercises/barbell-bench-press',
    );
    expect(
      Routes.exerciseIdFromRoute('/train/exercises/barbell-bench-press'),
      'barbell-bench-press',
    );
    expect(
      Routes.exerciseIdFromRoute('/train/exercises/close-grip%20bench'),
      'close-grip bench',
    );
    expect(Routes.exerciseIdFromRoute('/train'), isNull);
    expect(Routes.exerciseIdFromRoute('/train/exercises/'), isNull);
    expect(Routes.exerciseIdFromRoute(null), isNull);
  });

  test('routine routes round trip and exclude builder routes', () {
    expect(Routes.routines, '/train/routines');
    expect(Routes.routineDetail('routine-1'), '/train/routines/routine-1');
    expect(Routes.routineIdFromRoute('/train/routines/routine-1'), 'routine-1');
    expect(Routes.routineIdFromRoute('/train/routines/push%20day'), 'push day');
    expect(Routes.routineIdFromRoute('/train/routines'), isNull);
    expect(Routes.routineIdFromRoute('/train/routines/'), isNull);
    expect(Routes.routineIdFromRoute('/train/routines/new'), isNull);
    expect(Routes.routineIdFromRoute('/train/routines/routine-1/edit'), isNull);
    expect(Routes.routineIdFromRoute('/train'), isNull);
    expect(Routes.routineIdFromRoute(null), isNull);
  });

  test('routine builder routes round trip and are excluded from tabs', () {
    expect(Routes.routineNew, '/train/routines/new');
    expect(Routes.routineEdit('routine-1'), '/train/routines/routine-1/edit');
    expect(
      Routes.routineEditIdFromRoute('/train/routines/routine-1/edit'),
      'routine-1',
    );
    expect(
      Routes.routineEditIdFromRoute('/train/routines/push%20day/edit'),
      'push day',
    );
    expect(Routes.routineEditIdFromRoute('/train/routines/new'), isNull);
    expect(Routes.routineEditIdFromRoute('/train/routines//edit'), isNull);
    expect(Routes.routineEditIdFromRoute('/train/routines/routine-1'), isNull);
    expect(Routes.routineEditIdFromRoute(null), isNull);
    expect(Routes.isRoutineBuilderRoute(Routes.routineNew), isTrue);
    expect(
      Routes.isRoutineBuilderRoute('/train/routines/routine-1/edit'),
      isTrue,
    );
    expect(Routes.isRoutineBuilderRoute('/train/routines/routine-1'), isFalse);
    expect(Routes.isRoutineBuilderRoute(Routes.routines), isFalse);
    expect(Routes.isRoutineBuilderRoute(null), isFalse);
  });
}
