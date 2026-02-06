// features/contact/domain/repositories/contact_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

abstract class ContactRepository {
  Future<Either<Failure, Unit>> addContact(String contactId, {String? note});
}
