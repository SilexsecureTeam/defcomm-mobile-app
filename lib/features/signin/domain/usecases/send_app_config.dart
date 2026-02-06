import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/signin/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class SendAppConfig {
  final AuthRepository repository;
  SendAppConfig(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> config) {
    return repository.sendAppConfiguration(config);
  }
}