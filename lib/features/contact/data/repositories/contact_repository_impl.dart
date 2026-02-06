// features/contact/data/repositories/contact_repository_impl.dart
import 'package:defcomm/features/contact/data/datasources/contact_remote_datasource.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;

  ContactRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Unit>> addContact(String contactId, {String? note}) async {
    try {
      await remoteDataSource.addContact(contactId, note: note);
      return Right(unit);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
