import 'package:uuid/uuid.dart';

/// One entry in a project's local activity timeline — structural changes
/// only (never a per-keystroke log).
class ActivityEntry {
  final String id;
  final DateTime timestamp;
  final String message;

  ActivityEntry({String? id, DateTime? timestamp, required this.message})
    : id = id ?? const Uuid().v4(),
      timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    id: json['id'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
    message: json['message'] as String? ?? '',
  );
}
