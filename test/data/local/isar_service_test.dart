import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/local/isar_service.dart';
import 'package:isar/isar.dart';

void main() {
  test('allows a new attempt after database initialization fails', () async {
    var attempts = 0;

    Future<Isar> fail(String message) async {
      attempts += 1;
      throw StateError(message);
    }

    await expectLater(
      IsarService.getInstanceForTesting(() => fail('first failure')),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      IsarService.getInstanceForTesting(() => fail('second failure')),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'second failure',
        ),
      ),
    );

    expect(attempts, 2);
  });
}
