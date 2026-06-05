// lib/features/attendance/domain/entities/attendance_entity.dart
class AttendanceEntity {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String course;
  final String room;
  final String teacherName;
  final DateTime scannedAt;

  const AttendanceEntity({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.course,
    required this.room,
    required this.teacherName,
    required this.scannedAt,
  });
}

// ── Session Entity ────────────────────────────────────────────
class SessionEntity {
  final String sessionId;
  final String course;
  final String room;
  final String teacherId;
  final String teacherName;
  final DateTime createdAt;
  final DateTime expiresAt;

  const SessionEntity({
    required this.sessionId,
    required this.course,
    required this.room,
    required this.teacherId,
    required this.teacherName,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}
