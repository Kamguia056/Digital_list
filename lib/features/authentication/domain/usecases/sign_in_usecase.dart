// lib/features/authentication/domain/usecases/sign_in_usecase.dart
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  const SignInUseCase(this.repository);

  @override
  Future<UserEntity> call(SignInParams params) {
    return repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

// ── SignOut ──────────────────────────────────────────────────
class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  const SignOutUseCase(this.repository);

  @override
  Future<void> call(NoParams params) => repository.signOut();
}

// ── Reset Password ───────────────────────────────────────────
class ResetPasswordUseCase implements UseCase<void, String> {
  final AuthRepository repository;
  const ResetPasswordUseCase(this.repository);

  @override
  Future<void> call(String email) => repository.resetPassword(email);
}
