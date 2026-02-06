import 'package:equatable/equatable.dart';

class UnknownGroupMember extends Equatable {
  final String id;
  final int? memberId;
  final String? name;
  final String? role; // optional, if you want to show if they are admin
  final String? imageUrl; // placeholder if you have one

  const UnknownGroupMember({
    required this.id,
    required this.memberId,
    required this.name,
    this.role,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, memberId, name, role, imageUrl];
}