class GroupMember {
  final String id;          // encrypted id
  final String displayName; // member_name or fallback

  GroupMember({required this.id, required this.displayName});
}
