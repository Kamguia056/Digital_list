import 'package:flutter_test/flutter_test.dart';
import 'package:dlist/features/authentication/domain/entities/user_entity.dart';
import 'package:dlist/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:dlist/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dlist/core/usecases/usecase.dart';

// ── Stub manuel (sans build_runner) ──────────────────────────
class FakeAuthRepository implements AuthRepository {
  final UserEntity? returnUser;
  final Exception? throwError;

  FakeAuthRepository({this.returnUser, this.throwError});

  @override
  Future<UserEntity> signIn({required String email, required String password}) async {
    if (throwError != null) throw throwError!;
    return returnUser!;
  }

  @override
  Future<UserEntity> signUpStudent({
    required String name,
    required String email,
    required String password,
  }) async => returnUser!;

  @override
  Future<UserEntity> signUpTeacher({
    required String name,
    required String email,
    required String password,
    required String invitationCode,
  }) async => returnUser!;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<UserEntity?> getCurrentUser() async => returnUser;

  @override
  Future<void> bindNewDevice({
    required String email,
    required String password,
  }) async {}

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();
}

// ────────────────────────────────────────────────────────────
void main() {
  final tUser = UserEntity(
    uid: 'uid_123',
    name: 'Jean Dupont',
    email: 'jean@test.com',
    role: 'student',
  );

  group('SignInUseCase', () {
    test('retourne UserEntity en cas de succès', () async {
      final repo = FakeAuthRepository(returnUser: tUser);
      final useCase = SignInUseCase(repo);

      final result = await useCase(
        const SignInParams(email: 'jean@test.com', password: 'password123'),
      );

      expect(result.uid, 'uid_123');
      expect(result.email, 'jean@test.com');
      expect(result.name, 'Jean Dupont');
    });

    test('lance une exception si credentials invalides', () async {
      final repo = FakeAuthRepository(
        throwError: Exception('Identifiants incorrects'),
      );
      final useCase = SignInUseCase(repo);

      expect(
        () => useCase(
          const SignInParams(email: 'wrong@test.com', password: 'wrong'),
        ),
        throwsException,
      );
    });

    test('lance une exception si compte bloqué', () async {
      final repo = FakeAuthRepository(
        throwError: Exception('user-blocked'),
      );
      final useCase = SignInUseCase(repo);

      expect(
        () => useCase(
          const SignInParams(email: 'blocked@test.com', password: 'pass'),
        ),
        throwsException,
      );
    });
  });

  group('SignOutUseCase', () {
    test('appelle signOut sans erreur', () async {
      final repo = FakeAuthRepository();
      final useCase = SignOutUseCase(repo);
      expect(() => useCase(NoParams()), returnsNormally);
    });
  });

  group('UserEntity', () {
    test('isStudent est true pour role student', () {
      final user = UserEntity(uid: '1', name: 'A', email: 'a@b.com', role: 'student');
      expect(user.isStudent, true);
      expect(user.isTeacher, false);
      expect(user.isAdmin, false);
    });

    test('isTeacher est true pour role teacher', () {
      final user = UserEntity(uid: '2', name: 'B', email: 'b@b.com', role: 'teacher');
      expect(user.isTeacher, true);
      expect(user.isStudent, false);
    });

    test('isAdmin est true pour role admin', () {
      final user = UserEntity(uid: '3', name: 'C', email: 'c@b.com', role: 'admin');
      expect(user.isAdmin, true);
    });

    test('isBlocked est false par défaut', () {
      final user = UserEntity(uid: '4', name: 'D', email: 'd@b.com', role: 'student');
      expect(user.isBlocked, false);
    });

    test('isBlocked est true si spécifié', () {
      final user = UserEntity(
        uid: '5',
        name: 'E',
        email: 'e@b.com',
        role: 'student',
        isBlocked: true,
      );
      expect(user.isBlocked, true);
    });
  });
}
