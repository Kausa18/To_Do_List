// lib/screens/todo_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().load();
    });
  }

  @override
  void dispose() {
    _newController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(BuildContext ctx, Task task) async {
    final titleController = TextEditingController(text: task.title);
    DateTime? pickedDue = task.dueDate;

    final result = await showDialog<bool>(
      context: ctx,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(pickedDue != null ? "Due: ${pickedDue?.toLocal().toString().split(' ').first}" : 'No due date'),
                    ),
                    TextButton(
                      child: const Text('Pick Date'),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: pickedDue ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) setState(() => pickedDue = picked);
                      },
                    ),
                    if (pickedDue != null)
                      IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => pickedDue = null)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
            ],
          );
        });
      },
    );

    if (result == true) {
      // ignore: use_build_context_synchronously
      final provider = context.read<TaskProvider>();
      final updated = Task(
        id: task.id,
        title: titleController.text.trim(),
        done: task.done,
        createdAt: task.createdAt,
        dueDate: pickedDue,
      );
      await provider.updateTask(updated);
    }
  }

  Future<void> _addNew(TaskProvider provider) async {
    final text = _newController.text.trim();
    if (text.isEmpty) return;
    final newTask = Task(title: text);
    await provider.addTask(newTask);
    _newController.clear();
  }

  void _showUndoSnack(BuildContext context, Task removed) {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text('Deleted "${removed.title}"'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await provider.addTask(removed);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(builder: (context, provider, _) {
      final tasks = provider.visibleTasks;
      return Scaffold(
        appBar: AppBar(
          title: const Text('To-Do (Provider)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                  items: [
                    PopupMenuItem(value: SortMode.createdDesc, child: const Text('Newest')),
                    PopupMenuItem(value: SortMode.createdAsc, child: const Text('Oldest')),
                    PopupMenuItem(value: SortMode.dueDateAsc, child: const Text('Due date ↑')),
                    PopupMenuItem(value: SortMode.dueDateDesc, child: const Text('Due date ↓')),
                    PopupMenuItem(value: SortMode.doneLast, child: const Text('Done last')),
                  ],
                ).then((value) {
                  if (value != null) provider.setSortMode(value);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                for (final t in List.from(provider.allTasks)) {
                  await provider.removeTask(t.id);
                }
              },
              tooltip: 'Clear all',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Search tasks...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _newController,
                    decoration: const InputDecoration(hintText: 'New task', border: OutlineInputBorder()),
                    onSubmitted: (_) => _addNew(provider),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _addNew(provider), child: const Text('Add')),
              ]),
            ),
          ),
        ),
        body: tasks.isEmpty
            ? const Center(child: Text('No tasks yet. Add some!'))
            : ReorderableListView.builder(
                itemCount: tasks.length,
                onReorder: (oldIndex, newIndex) async {
                  final t = tasks[oldIndex];
                  final all = provider.allTasks;
                  final oldAllIndex = all.indexWhere((x) => x.id == t.id);
                  int targetAllIndex;
                  if (newIndex >= tasks.length) {
                    targetAllIndex = all.length - 1;
                  } else {
                    final targetTask = tasks[newIndex];
                    targetAllIndex = all.indexWhere((x) => x.id == targetTask.id);
                  }
                  await provider.reorder(oldAllIndex, targetAllIndex);
                },
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: ValueKey('dismiss_${task.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      final removed = await provider.removeTask(task.id);
                      // ignore: use_build_context_synchronously
                      if (removed != null) _showUndoSnack(context, removed);
                    },
                    child: Card(
                      key: ValueKey(task.id),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: TaskTile(
                        task: task,
                        onToggle: (_) => provider.toggleDone(task),
                        onDelete: () async {
                          final removed = await provider.removeTask(task.id);
                          // ignore: use_build_context_synchronously
                          if (removed != null) _showUndoSnack(context, removed);
                        },
                        onEdit: () => _showEditDialog(context, task),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}
