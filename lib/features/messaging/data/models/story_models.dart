import '../../domain/entities/story.dart';

class StoryModel extends Story {
  const StoryModel({
    required super.id,
    required super.contactIdEncrypt,
    required super.contactId,
    required super.name,
    required super.email,
    required super.phone,
    required super.status,
    required super.imageUrl,
  });

  factory StoryModel.fromJson(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] as String,
      contactIdEncrypt: map['contact_id_encrypt'] as String?,
      contactId: map['contact_id'] as int?,
      name: map['contact_name'] as String?,
      email: map['contact_email'] as String?,
      phone: map['contact_phone'] as String?,
      status: map['contact_status'] as String?,
      
      imageUrl: 'images/defcomm_logo_1.png',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id_encrypt': contactIdEncrypt,
      'contact_id': contactId,
      'contact_name': name,
      'contact_email': email,
      'contact_phone': phone,
      'contact_status': status,
    };
  }
}