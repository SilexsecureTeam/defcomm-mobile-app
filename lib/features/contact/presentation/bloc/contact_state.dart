// features/contact/presentation/bloc/contact_state.dart
import 'package:equatable/equatable.dart';

abstract class ContactState extends Equatable {
  const ContactState();

  @override
  List<Object?> get props => [];
}

class ContactInitial extends ContactState {
  const ContactInitial();
}

class ContactLoading extends ContactState {
  const ContactLoading();
}

class ContactSuccess extends ContactState {
  final String message; 
  const ContactSuccess([this.message = "Added"]);

  @override
  List<Object?> get props => [message];
}

class ContactFailure extends ContactState {
  final String error;
  const ContactFailure(this.error);

  @override
  List<Object?> get props => [error];
}
