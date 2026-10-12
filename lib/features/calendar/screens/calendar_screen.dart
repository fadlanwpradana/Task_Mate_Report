import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../tasks/screens/add_task_screen.dart';
import '../../tasks/services/task_repository.dart';
import '../../tasks/widgets/task_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).tasks;
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selected, now);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        actions: [
          IconButton(
            tooltip: l10n.addTask,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddTaskScreen(initialDate: _selected),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final dayTasks = repository.tasksDueOn(_selected);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              FormatUtils.monthYear(context, _month),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.previousMonth,
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            tooltip: l10n.nextMonth,
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _MonthGrid(
                        month: _month,
                        selected: _selected,
                        repository: repository,
                        onSelected: (day) => setState(() => _selected = day),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: isToday
                    ? l10n.todaysTasks
                    : l10n.tasksForDate(FormatUtils.date(context, _selected)),
              ),
              const SizedBox(height: 8),
              if (dayTasks.isEmpty)
                EmptyState(
                  title: l10n.noTasksOnDay,
                  icon: Icons.event_available_rounded,
                )
              else
                for (final task in dayTasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TaskDueRow(task: task),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.repository,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selected;
  final TaskRepository repository;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final mondayFirst = AppScope.of(context).profile.weekStartsMonday;
    final weekdays = FormatUtils.weekdays(context, mondayFirst: mondayFirst);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month).weekday;
    final leadingBlanks = mondayFirst ? firstWeekday - 1 : firstWeekday % 7;
    final cellCount = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            for (final name in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(month.year, month.month, dayNumber);
            final isSelected = DateUtils.isSameDay(day, selected);
            final isToday = DateUtils.isSameDay(day, today);
            final hasTasks = repository.tasks.any((t) => t.isDueOn(day));
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(day),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.brand : null,
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.skyBlue, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                    if (hasTasks)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : AppColors.sageGreen,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
