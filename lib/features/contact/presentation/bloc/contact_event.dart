import 'package:equatable/equatable.dart';

abstract class ContactEvent extends Equatable {
  const ContactEvent();

  @override
  List<Object?> get props => [];
}

class AddContactEvent extends ContactEvent {
  final String contactId;
  final String? note;

  const AddContactEvent({required this.contactId, this.note});

  @override
  List<Object?> get props => [contactId, note];
}
