// lib/features/attendance/domain/repositories/attendance_repository.dart
import '../entities/attendance_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../usecases/validate_presence_usecase.dart';

abstract class AttendanceRepository {
  Future<ValidatePresenceResult> validatePresence({
    required String sessionId,
    double? latitude,
    double? longitude,
  });

  Stream<List<AttendanceEntity>> getSessionAttendanceStream(String sessionId);

  Stream<List<AttendanceEntity>> getStudentHistoryStream(String studentId);

  Future<List<AttendanceEntity>> getAttendanceByCourse(String courseId);

  Future<double> getAttendanceRate({
    required String studentId,
    String? courseId,
  });

  Future<void> createSession({
    required String sessionId,
    required String course,
    required String room,
    required String teacherName,
    required DateTime expiresAt,
  });

  Future<void> closeSession(String sessionId);

  Stream<List<SessionEntity>> getActiveSessions();
}
