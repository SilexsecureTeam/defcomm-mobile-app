// features/contact/presentation/bloc/contact_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'contact_event.dart';
import 'contact_state.dart';
import '../../domain/usecases/add_contact.dart';
import '../../../../core/error/failures.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final AddContact addContactUseCase;

  ContactBloc({required this.addContactUseCase}) : super(const ContactInitial()) {
    on<AddContactEvent>(_onAddContact);
  }

  Future<void> _onAddContact(AddContactEvent event, Emitter<ContactState> emit) async {
    emit(const ContactLoading());

    final Either<Failure, Unit> result = await addContactUseCase(contactId: event.contactId, note: event.note);

    result.match(
      (failure) => emit(ContactFailure(failure.message)),
      (_) => emit(const ContactSuccess("Contact added successfully")),
    );
  }
}
