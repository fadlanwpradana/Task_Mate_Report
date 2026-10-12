import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/task_model.dart';
import '../widgets/subtask_dialog.dart';
import '../widgets/task_widgets.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  void _edit(BuildContext context, TaskModel task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => EditTaskScreen(task: task)));
  }

  Future<void> _confirmDelete(BuildContext context, TaskModel task) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTaskQuestion),
        content: Text(l10n.deleteTaskMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = AppScope.of(context).tasks;
    Navigator.of(context).pop();
    await repository.delete(task.id);
  }

  Future<void> _showOptions(BuildContext context, TaskModel task) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.navy),
              title: Text(l10n.editTask),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(l10n.deleteTask),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') _edit(context, task);
    if (action == 'delete') await _confirmDelete(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final task = repository.byId(taskId);
        if (task == null) return Scaffold(appBar: AppBar());
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.taskDetails),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: l10n.moreOptions,
                onPressed: () => _showOptions(context, task),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _Summary(task: task),
              const SizedBox(height: 12),
              _Progress(task: task),
              const SizedBox(height: 16),
              _SubtasksSection(task: task),
              const SizedBox(height: 12),
              _ReminderTile(task: task),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _edit(context, task),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.edit),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.skyBlue.withValues(
                          alpha: 0.16,
                        ),
                        foregroundColor: AppColors.navy,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _confirmDelete(context, task),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.delete),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.highPriority.withValues(
                          alpha: 0.16,
                        ),
                        foregroundColor: Colors.red.shade400,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton.icon(
                onPressed: () {
                  repository.setCompleted(task.id, !task.isCompleted);
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  task.isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  task.isCompleted ? l10n.markActive : l10n.markComplete,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = FormatUtils.priorityColor(task.priority);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.priorityPill(
                  FormatUtils.priority(l10n, task.priority).toUpperCase(),
                ),
                style: TextStyle(
                  color: Color.lerp(color, AppColors.navy, 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              FormatUtils.taskCategory(l10n, task.category),
              style: TextStyle(color: AppColors.secondaryText),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                style: TextStyle(color: AppColors.secondaryText, height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.skyBlue,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deadline,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      Text(
                        '${TaskDateUtils.dueDay(context, task.deadline, withYear: true)}'
                        ' · ${TaskDateUtils.time(context, task.deadline)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.timer_outlined,
                  color: Colors.red.shade300,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: DeadlineCountdown(
                    deadline: task.deadline,
                    isCompleted: task.isCompleted,
                    showOverdueBadge: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.sageGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.progress,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${(task.progress * 100).round()}%',
                style: TextStyle(
                  color: Color.lerp(AppColors.sageGreen, AppColors.navy, 0.3),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 7,
              backgroundColor: AppColors.white,
              color: AppColors.sageGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtasksSection extends StatelessWidget {
  const _SubtasksSection({required this.task});

  final TaskModel task;

  Future<void> _addSubtask(BuildContext context) async {
    final repository = AppScope.of(context).tasks;
    final title = await showAddSubtaskDialog(context);
    if (title != null) await repository.addSubtask(task.id, title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.subtasks, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              l10n.subtasksCount(task.completedSubtasks, task.subtasks.length),
              style: const TextStyle(
                color: AppColors.skyBlue,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            IconButton(
              tooltip: l10n.addSubtask,
              onPressed: () => _addSubtask(context),
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.skyBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (task.subtasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.noSubtasksYet,
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: (oldIndex, newIndex) =>
                repository.moveSubtask(task.id, oldIndex, newIndex),
            children: [
              for (var i = 0; i < task.subtasks.length; i++)
                Card(
                  key: ValueKey(task.subtasks[i].id),
                  margin: const EdgeInsets.only(bottom: 6),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    dense: true,
                    onTap: () =>
                        repository.toggleSubtask(task.id, task.subtasks[i].id),
                    leading: _SubtaskCheck(done: task.subtasks[i].isDone),
                    title: Text(
                      task.subtasks[i].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: task.subtasks[i].isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.removeSubtask(task.subtasks[i].title),
                          onPressed: () => repository.removeSubtask(
                            task.id,
                            task.subtasks[i].id,
                          ),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(
                            Icons.drag_indicator,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SubtaskCheck extends StatelessWidget {
  const _SubtaskCheck({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? AppColors.sageGreen : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? AppColors.sageGreen : AppColors.secondaryText,
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 15)
          : null,
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = ReminderTimes.upcoming(task);
    final subtitle = !task.reminderEnabled
        ? l10n.tapToEnable
        : !AppScope.of(context).profile.taskReminders
        ? l10n.remindersOffInProfile
        : next.isEmpty
        ? l10n.noUpcomingReminder
        : l10n.nextReminder(
            '${TaskDateUtils.dueDay(context, next.first)}, '
            '${TaskDateUtils.time(context, next.first)}',
          );
    return Material(
      color: AppColors.highPriority.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppScope.of(context).tasks.toggleReminder(task.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(
                task.reminderEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: task.reminderEnabled
                    ? Colors.red.shade400
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.reminderEnabled
                          ? l10n.reminderSet
                          : l10n.reminderOff,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: task.reminderEnabled,
                activeTrackColor: AppColors.sageGreen,
                onChanged: (_) =>
                    AppScope.of(context).tasks.toggleReminder(task.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
