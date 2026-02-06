import '../../domain/entities/linked_device.dart';

class LinkedDeviceModel extends LinkedDevice {
  const LinkedDeviceModel({
    required super.id,
    required super.name,
    required super.platform,
    required super.lastActive,
  });

  factory LinkedDeviceModel.fromJson(Map<String, dynamic> json) {
    String constructedName = json['browser'] ?? 'Unknown Browser';
    
    return LinkedDeviceModel(
      id: json['id']?.toString() ?? '',
      name: constructedName,
      platform: json['os']?.toString() ?? 'Unknown OS',
      lastActive: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'browser': name,    
      'os': platform,
      'updated_at': lastActive.toIso8601String(),
    };
  }
}