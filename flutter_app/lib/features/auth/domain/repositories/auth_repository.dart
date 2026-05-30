import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(String email, String password, String role);
  Future<Either<Failure, void>>       logout();
  Future<Either<Failure, void>>       forgotPassword(String email);
  Future<Either<Failure, void>>       verifyEmail();
  Stream<UserEntity?>                 authStateChanges();
  UserEntity?                         getCurrentUser();
}
