import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../tasks/widgets/task_widgets.dart';

/// Body of the Home tab.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.firstName,
    required this.onSeeAllToday,
    required this.onAddTask,
    super.key,
  });

  final String? firstName;

  /// Opens the task list filtered to today.
  final VoidCallback onSeeAllToday;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final todayTasks = repository.todayActiveTasks;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              firstName == null ? l10n.hello : l10n.helloName(firstName!),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.homeSubtitle,
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 22),
            _ProgressCard(
              done: repository.completedCount,
              total: repository.tasks.length,
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l10n.priorityTask),
            const SizedBox(height: 8),
            PriorityTaskCard(task: repository.priorityTask),
            const SizedBox(height: 14),
            SectionHeader(
              title: l10n.todaysTasks,
              actionLabel: l10n.seeAll,
              onAction: onSeeAllToday,
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty) ...[
              EmptyState(
                title: l10n.noActiveTasksToday,
                icon: Icons.task_alt_rounded,
              ),
              Center(
                child: TextButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addTask),
                ),
              ),
            ] else
              for (final task in todayTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TaskDueRow(task: task),
                ),
          ],
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = total == 0 ? 0.0 : done / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taskProgress,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? l10n.noTasksProgress
                        : l10n.tasksCompleted(done, total),
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 18),
            SizedBox.square(
              dimension: 66,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: AppColors.border,
                    color: AppColors.sageGreen,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
