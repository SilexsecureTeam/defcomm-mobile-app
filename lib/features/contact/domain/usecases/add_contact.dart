import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/contact_repository.dart';

class AddContact {
  final ContactRepository repository;

  AddContact(this.repository);

  Future<Either<Failure, Unit>> call({required String contactId, String? note}) {
    return repository.addContact(contactId, note: note);
  }
}
