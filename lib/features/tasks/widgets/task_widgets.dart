import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../screens/task_detail_screen.dart';

Future<void> openTaskDetail(BuildContext context, TaskModel task) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskId: task.id)),
  );
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: FormatUtils.priority(
        AppLocalizations.of(context),
        priority,
      ).toUpperCase(),
      color: FormatUtils.priorityColor(priority),
    );
  }
}

class OverdueBadge extends StatelessWidget {
  const OverdueBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.highPriority.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppLocalizations.of(context).overdueBadge,
        style: TextStyle(
          color: Colors.red.shade400,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Live "2 days left" / "3 hours overdue" text, refreshed every minute.
class DeadlineCountdown extends StatefulWidget {
  const DeadlineCountdown({
    required this.deadline,
    this.isCompleted = false,
    this.showOverdueBadge = false,
    this.fontSize = 12,
    super.key,
  });

  final DateTime deadline;
  final bool isCompleted;
  final bool showOverdueBadge;
  final double fontSize;

  @override
  State<DeadlineCountdown> createState() => _DeadlineCountdownState();
}

class _DeadlineCountdownState extends State<DeadlineCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.isCompleted) {
      return Text(
        l10n.completedLabel,
        style: TextStyle(
          color: AppColors.sageGreen,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final overdue = TaskDateUtils.isOverdue(widget.deadline);
    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (overdue && widget.showOverdueBadge) const OverdueBadge(),
        Text(
          TaskDateUtils.countdown(l10n, widget.deadline),
          style: TextStyle(
            color: overdue ? Colors.red.shade400 : AppColors.secondaryText,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Task list card: completion checkbox, priority, category, deadline with
/// countdown, reminder toggle, and subtask progress.
class TaskCard extends StatelessWidget {
  const TaskCard({required this.task, required this.onTap, super.key});

  final TaskModel task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    final color = FormatUtils.priorityColor(task.priority);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    shape: const CircleBorder(),
                    activeColor: AppColors.sageGreen,
                    onChanged: (value) {
                      if (value != null) {
                        repository.setCompleted(task.id, value);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    FormatUtils.taskCategory(l10n, task.category),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 15,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${TaskDateUtils.dueDay(context, task.deadline)}, '
                      '${TaskDateUtils.time(context, task.deadline)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DeadlineCountdown(
                        deadline: task.deadline,
                        isCompleted: task.isCompleted,
                        showOverdueBadge: true,
                      ),
                    ),
                    IconButton(
                      tooltip: task.reminderEnabled
                          ? l10n.turnReminderOff
                          : l10n.turnReminderOn,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => repository.toggleReminder(task.id),
                      icon: Icon(
                        task.reminderEnabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        size: 19,
                        color: task.reminderEnabled
                            ? AppColors.navy
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.progressPercent((task.progress * 100).round()),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        color: task.isCompleted ? AppColors.sageGreen : color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home "Priority Task" card for the single most pressing task.
class PriorityTaskCard extends StatelessWidget {
  const PriorityTaskCard({required this.task, super.key});

  final TaskModel? task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = this.task;
    if (task == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: Text(
              l10n.allTasksCompleted,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }
    final color = FormatUtils.priorityColor(task.priority);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTaskDetail(context, task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Text(
                  FormatUtils.taskCategory(l10n, task.category),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              if (task.isOverdue)
                const Padding(
                  padding: EdgeInsets.only(left: 32, top: 6),
                  child: OverdueBadge(),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${TaskDateUtils.dueDay(context, task.deadline)}, '
                      '${TaskDateUtils.time(context, task.deadline)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  DeadlineCountdown(deadline: task.deadline),
                  const SizedBox(width: 12),
                  Icon(
                    task.reminderEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 16,
                    color: task.reminderEnabled
                        ? AppColors.navy
                        : AppColors.secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(task.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  color: task.isOverdue ? AppColors.highPriority : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact row with a priority color bar, category, due time, and countdown
/// (Home "Today's tasks" and the calendar).
class TaskDueRow extends StatelessWidget {
  const TaskDueRow({required this.task, super.key});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTaskDetail(context, task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 44,
                decoration: BoxDecoration(
                  color: FormatUtils.priorityColor(task.priority),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatUtils.taskCategory(l10n, task.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    TaskDateUtils.time(context, task.deadline),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  DeadlineCountdown(
                    deadline: task.deadline,
                    isCompleted: task.isCompleted,
                    showOverdueBadge: true,
                    fontSize: 11,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
