// lib/features/attendance/domain/usecases/validate_presence_usecase.dart
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

class ValidatePresenceParams {
  final String sessionId;
  final double? latitude;
  final double? longitude;
  const ValidatePresenceParams({
    required this.sessionId,
    this.latitude,
    this.longitude,
  });
}

class ValidatePresenceResult {
  final bool success;
  final String message;
  final String? course;
  final String? room;
  final String? teacherName;

  const ValidatePresenceResult({
    required this.success,
    required this.message,
    this.course,
    this.room,
    this.teacherName,
  });
}

class ValidatePresenceUseCase
    implements UseCase<ValidatePresenceResult, ValidatePresenceParams> {
  final AttendanceRepository repository;
  const ValidatePresenceUseCase(this.repository);

  @override
  Future<ValidatePresenceResult> call(ValidatePresenceParams params) {
    return repository.validatePresence(
      sessionId: params.sessionId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
