import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/priority_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/task_widgets.dart';

enum TaskFilter { all, today, upcoming, completed }

enum TaskSort { priority, newest, deadline, title }

/// Body of the Tasks tab.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.priority;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// After creating a task, show the full list with the newest task on top.
  void showNewest() {
    _searchController.clear();
    setState(() {
      _filter = TaskFilter.all;
      _sort = TaskSort.newest;
    });
  }

  /// From Home's "Today's tasks → See all": show only today's tasks.
  void showToday() {
    _searchController.clear();
    setState(() => _filter = TaskFilter.today);
  }

  List<TaskModel> _visible(List<TaskModel> tasks) {
    final now = DateTime.now();
    final query = _searchController.text.trim().toLowerCase();
    final visible = tasks.where((task) {
      final matchesFilter = switch (_filter) {
        TaskFilter.all => !task.isCompleted,
        TaskFilter.today =>
          !task.isCompleted && TaskDateUtils.isSameDay(task.deadline, now),
        TaskFilter.upcoming => !task.isCompleted && task.deadline.isAfter(now),
        TaskFilter.completed => task.isCompleted,
      };
      final matchesQuery =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          FormatUtils.taskCategory(
            AppLocalizations.of(context),
            task.category,
          ).toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    switch (_sort) {
      case TaskSort.priority:
        visible.sort((a, b) => PriorityUtils.compare(a, b, now: now));
      case TaskSort.newest:
        visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.deadline:
        visible.sort((a, b) => a.deadline.compareTo(b.deadline));
      case TaskSort.title:
        visible.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return visible;
  }

  Future<void> _openTask(TaskModel task) async {
    await openTaskDetail(context, task);
    if (!mounted) return;
    // Like V3: jump to the list where the task now lives.
    final updated = AppScope.of(context).tasks.byId(task.id);
    if (updated == null) return;
    setState(() {
      _filter = updated.isCompleted ? TaskFilter.completed : TaskFilter.all;
    });
  }

  Future<void> _chooseSort() async {
    final l10n = AppLocalizations.of(context);
    final sort = await showModalBottomSheet<TaskSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.sortTasksBy,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final option in TaskSort.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(switch (option) {
                  TaskSort.priority => l10n.sortPriority,
                  TaskSort.newest => l10n.sortNewest,
                  TaskSort.deadline => l10n.sortDeadline,
                  TaskSort.title => l10n.sortTitle,
                }),
                trailing: option == _sort
                    ? Icon(Icons.check_rounded, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (sort != null) setState(() => _sort = sort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final tasks = _visible(repository.tasks);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.myTasksSummary(
                      repository.activeCount,
                      repository.dueThisWeekCount,
                    ),
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.sortTasks,
                  onPressed: _chooseSort,
                  style: IconButton.styleFrom(backgroundColor: AppColors.white),
                  icon: Icon(Icons.tune_rounded, color: AppColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SearchField(
              hint: l10n.searchTasksHint,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            ChoiceChipRow<TaskFilter>(
              values: TaskFilter.values,
              selected: _filter,
              labelOf: (filter) => switch (filter) {
                TaskFilter.all => l10n.filterAll,
                TaskFilter.today => l10n.filterToday,
                TaskFilter.upcoming => l10n.filterUpcoming,
                TaskFilter.completed => l10n.filterCompleted,
              },
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  title: _searchController.text.trim().isNotEmpty
                      ? l10n.noResults
                      : _filter == TaskFilter.completed
                      ? l10n.noCompletedTasks
                      : l10n.noTasksInView,
                  description: l10n.checkOffHint,
                  icon: Icons.task_alt_rounded,
                ),
              )
            else
              for (final task in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskCard(task: task, onTap: () => _openTask(task)),
                ),
          ],
        );
      },
    );
  }
}
