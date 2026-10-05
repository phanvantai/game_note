/// Helpers for the backend's JSON conventions: ISO-8601 UTC timestamps with
/// millisecond precision.
DateTime? parseApiDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.parse(value);
  if (value is DateTime) return value;
  return null;
}

String toApiDate(DateTime value) => value.toUtc().toIso8601String();

String? toApiDateOrNull(DateTime? value) =>
    value == null ? null : toApiDate(value);

/// Casts a decoded JSON list into a list of maps, skipping anything else.
List<Map<String, dynamic>> apiMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> apiStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
