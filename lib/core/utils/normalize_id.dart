String normalizeId(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw;
  if (raw is int) return raw.toString();
  if (raw is Map && raw['id'] != null) return normalizeId(raw['id']);
  if (raw is Map && raw['member_id_encrpt'] != null) return normalizeId(raw['member_id_encrpt']);
  return raw.toString();
}
