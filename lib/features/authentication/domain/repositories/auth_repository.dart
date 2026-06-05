// lib/features/authentication/domain/repositories/auth_repository.dart
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<UserEntity> signUpStudent({
    required String name,
    required String email,
    required String password,
  });

  Future<UserEntity> signUpTeacher({
    required String name,
    required String email,
    required String password,
    required String invitationCode,
  });

  Future<void> signOut();

  Future<void> resetPassword(String email);

  Future<UserEntity?> getCurrentUser();

  Future<void> bindNewDevice({
    required String email,
    required String password,
  });

  Stream<UserEntity?> get authStateChanges;
}
