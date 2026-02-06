import 'package:equatable/equatable.dart';

class LinkedDevice extends Equatable {
  final String id;
  final String name;
  final String platform; 
  final DateTime lastActive;

  const LinkedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActive,
  });

  @override
  List<Object?> get props => [id, name, platform, lastActive];
}
