import 'package:flutter_test/flutter_test.dart';
import 'package:dlist/features/attendance/domain/entities/attendance_entity.dart';
import 'package:dlist/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dlist/features/attendance/domain/usecases/validate_presence_usecase.dart';

// ── Stub manuel ───────────────────────────────────────────────
class FakeAttendanceRepository implements AttendanceRepository {
  final ValidatePresenceResult _result;

  FakeAttendanceRepository(this._result);

  @override
  Future<ValidatePresenceResult> validatePresence({
    required String sessionId,
    double? latitude,
    double? longitude,
  }) async => _result;

  @override
  Stream<List<AttendanceEntity>> getSessionAttendanceStream(String sessionId) =>
      const Stream.empty();

  @override
  Stream<List<AttendanceEntity>> getStudentHistoryStream(String studentId) =>
      const Stream.empty();

  @override
  Future<List<AttendanceEntity>> getAttendanceByCourse(String courseId) async => [];

  @override
  Future<double> getAttendanceRate({
    required String studentId,
    String? courseId,
  }) async => 0.0;

  @override
  Future<void> createSession({
    required String sessionId,
    required String course,
    required String room,
    required String teacherName,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> closeSession(String sessionId) async {}

  @override
  Stream<List<SessionEntity>> getActiveSessions() => const Stream.empty();
}

// ────────────────────────────────────────────────────────────
void main() {
  const tSessionId = 'SESS-20260605-4827';

  const tSuccess = ValidatePresenceResult(
    success: true,
    message: 'Présence validée avec succès !',
    course: 'Algorithmique',
    room: 'Amphi 300',
    teacherName: 'Prof. Kamguia',
  );

  const tExpired = ValidatePresenceResult(
    success: false,
    message: 'Cette séance a expiré.',
  );

  const tNotFound = ValidatePresenceResult(
    success: false,
    message: "Cette séance n'existe pas.",
  );

  group('ValidatePresenceUseCase', () {
    test('retourne succès pour session valide', () async {
      final useCase = ValidatePresenceUseCase(FakeAttendanceRepository(tSuccess));

      final result = await useCase(
        const ValidatePresenceParams(sessionId: tSessionId),
      );

      expect(result.success, true);
      expect(result.course, 'Algorithmique');
      expect(result.room, 'Amphi 300');
      expect(result.teacherName, 'Prof. Kamguia');
    });

    test('retourne échec pour session expirée', () async {
      final useCase = ValidatePresenceUseCase(FakeAttendanceRepository(tExpired));

      final result = await useCase(
        const ValidatePresenceParams(sessionId: 'EXPIRED-SESSION'),
      );

      expect(result.success, false);
      expect(result.message, contains('expiré'));
    });

    test('retourne échec pour session inexistante', () async {
      final useCase = ValidatePresenceUseCase(FakeAttendanceRepository(tNotFound));

      final result = await useCase(
        const ValidatePresenceParams(sessionId: 'UNKNOWN'),
      );

      expect(result.success, false);
      expect(result.message, contains("n'existe pas"));
    });

    test('passe les coordonnées géographiques au repository', () async {
      double? capturedLat, capturedLon;

      final repo = _CapturingRepo(
        result: tSuccess,
        onCall: (lat, lon) {
          capturedLat = lat;
          capturedLon = lon;
        },
      );
      final useCase = ValidatePresenceUseCase(repo);

      await useCase(const ValidatePresenceParams(
        sessionId: tSessionId,
        latitude: 3.848,
        longitude: 11.502,
      ));

      expect(capturedLat, 3.848);
      expect(capturedLon, 11.502);
    });
  });

  group('SessionEntity', () {
    test('isExpired retourne true pour session déjà expirée', () {
      final session = SessionEntity(
        sessionId: 'TEST',
        course: 'Math',
        room: 'A1',
        teacherId: 'uid1',
        teacherName: 'Prof',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(session.isExpired, true);
    });

    test('isExpired retourne false pour session active', () {
      final session = SessionEntity(
        sessionId: 'TEST2',
        course: 'Physics',
        room: 'B2',
        teacherId: 'uid2',
        teacherName: 'Prof B',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
      );
      expect(session.isExpired, false);
    });

    test('remainingTime est positif pour session active', () {
      final session = SessionEntity(
        sessionId: 'TEST3',
        course: 'IT',
        room: 'C3',
        teacherId: 'uid3',
        teacherName: 'Prof C',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 25)),
      );
      expect(session.remainingTime.inMinutes, greaterThan(0));
    });
  });

  group('ValidatePresenceResult', () {
    test('success est true quand la présence est validée', () {
      const result = ValidatePresenceResult(success: true, message: 'OK');
      expect(result.success, true);
    });

    test('success est false en cas d\'échec', () {
      const result = ValidatePresenceResult(success: false, message: 'Erreur');
      expect(result.success, false);
    });
  });
}

// ── Repo capteur pour tester le passage de paramètres ────────
class _CapturingRepo extends FakeAttendanceRepository {
  final void Function(double? lat, double? lon) onCall;

  _CapturingRepo({required ValidatePresenceResult result, required this.onCall})
      : super(result);

  @override
  Future<ValidatePresenceResult> validatePresence({
    required String sessionId,
    double? latitude,
    double? longitude,
  }) async {
    onCall(latitude, longitude);
    return super.validatePresence(
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
