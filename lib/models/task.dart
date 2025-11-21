// lib/models/task.dart
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class Task {
  final String id;
  String title;
  bool done;
  DateTime createdAt;
  DateTime? dueDate;

  Task({
    String? id,
    required this.title,
    this.done = false,
    DateTime? createdAt,
    this.dueDate,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> m) {
    return Task(
      id: m['id'] as String?,
      title: m['title'] as String? ?? '',
      done: m['done'] as bool? ?? false,
      createdAt: DateTime.parse(m['createdAt'] as String),
      dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
    );
  }
}
