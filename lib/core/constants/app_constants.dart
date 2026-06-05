// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // Session
  static const int sessionExpiryMinutes = 30;
  static const double geoValidationRadiusKm = 5.0;
  static const int deviceLockDays = 30;

  // Collections Firestore
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String attendanceCollection = 'attendance';
  static const String coursesCollection = 'courses';
  static const String enrollmentsCollection = 'enrollments';
  static const String teacherRequestsCollection = 'teacher_requests';
  static const String notificationsCollection = 'notifications';

  // Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';

  // Routes
  static const String routeWelcome = '/';
  static const String routeLogin = '/login';
  static const String routeStudentHome = '/student_home';
  static const String routeTeacherHome = '/teacher_home';
  static const String routeAdminHome = '/admin_home';
  static const String routeScanner = '/scanner';

  // Invitation code prefix
  static const String teacherCodePrefix = 'TEACH-';
}
