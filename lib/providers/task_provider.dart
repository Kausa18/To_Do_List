// lib/providers/task_provider.dart
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

enum SortMode { createdDesc, createdAsc, dueDateAsc, dueDateDesc, doneLast }

class TaskProvider extends ChangeNotifier {
  final StorageService _storage;
  final List<Task> _tasks = [];
  String _searchQuery = '';
  SortMode _sortMode = SortMode.createdDesc;

  TaskProvider(this._storage);

  List<Task> get allTasks => List.unmodifiable(_tasks);

  List<Task> get visibleTasks {
    var list = _tasks.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortMode) {
      case SortMode.createdDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.createdAsc:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortMode.dueDateAsc:
        list.sort((a, b) { /* handles nulls */ 
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case SortMode.dueDateDesc:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case SortMode.doneLast:
        list.sort((a, b) {
          if (a.done == b.done) return 0;
          return a.done ? 1 : -1;
        });
        break;
    }

    return list;
  }

  Future<void> load() async {
    final loaded = await _storage.loadTasks();
    _tasks
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> addTask(Task t) async {
    _tasks.insert(0, t);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> updateTask(Task t) async {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    _tasks[i] = t;
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> toggleDone(Task t) async {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    _tasks[i].done = !_tasks[i].done;
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<Task?> removeTask(String id) async {
    final i = _tasks.indexWhere((x) => x.id == id);
    if (i == -1) return null;
    final removed = _tasks.removeAt(i);
    await _storage.saveTasks(_tasks);
    notifyListeners();
    return removed;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortMode(SortMode m) {
    _sortMode = m;
    notifyListeners();
  }
}
