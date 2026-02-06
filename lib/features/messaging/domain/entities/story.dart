
import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String? contactIdEncrypt;
  final int? contactId;
  final String? name;
  final String? email;
  final String? phone;
  final String? status; 
  final String imageUrl; 

  const Story({
    required this.id,
    required this.contactIdEncrypt,
    required this.contactId,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        contactIdEncrypt,
        contactId,
        name,
        email,
        phone,
        status,
        imageUrl,
      ];
}