import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/subtask_model.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../widgets/subtask_dialog.dart';

/// How the Add Task screen was closed: a task was created, or a bottom-bar
/// tab was tapped.
class AddTaskResult {
  const AddTaskResult({this.created = false, this.tabIndex});

  final bool created;
  final int? tabIndex;
}

/// Creates a task, following Task Mate V3's Add Task screen.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({this.initialDate, super.key});

  /// Pre-selected deadline day (e.g. from the calendar).
  final DateTime? initialDate;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String>? _subtasks;

  TaskCategory _category = TaskCategory.academic;
  late DateTime _deadline;
  TaskPriority _priority = TaskPriority.medium;
  bool _reminderEnabled = true;
  bool _isSaving = false;
  String? _titleError;
  String? _deadlineError;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final day = widget.initialDate;
    _deadline = day == null
        ? tomorrow
        : DateTime(
            day.year,
            day.month,
            day.day,
            tomorrow.hour,
            tomorrow.minute,
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // V3 starts every new task with one example step.
    _subtasks ??= [AppLocalizations.of(context).defaultSubtask];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 3650)),
      helpText: l10n.selectDeadlineDate,
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
      helpText: l10n.selectDeadlineTime,
    );
    if (!mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
      _deadlineError = null;
    });
  }

  Future<void> _addSubtask() async {
    final subtask = await showAddSubtaskDialog(context);
    if (!mounted || subtask == null) return;
    setState(() => _subtasks!.add(subtask));
  }

  Future<void> _createTask() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final isDeadlinePast = !_deadline.isAfter(DateTime.now());
    setState(() {
      _titleError = title.isEmpty ? l10n.enterTaskTitle : null;
      _deadlineError = isDeadlinePast ? l10n.chooseFutureDeadline : null;
    });
    if (title.isEmpty || isDeadlinePast) return;

    setState(() => _isSaving = true);
    await AppScope.of(context).tasks.add(
      TaskModel(
        id: generateId(),
        title: title,
        description: _descriptionController.text.trim(),
        category: _category.name,
        deadline: _deadline,
        priority: _priority,
        reminderEnabled: _reminderEnabled,
        subtasks: [
          for (final subtask in _subtasks!)
            SubtaskModel(id: generateId(), title: subtask),
        ],
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pop(const AddTaskResult(created: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtasks = _subtasks!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addTaskTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppColors.navy, size: 28),
                ),
              ],
            ),
            Text(
              l10n.addTaskSubtitle,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            _Label(l10n.titleLabel),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                hintText: l10n.taskTitleHint,
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                errorText: _titleError,
              ),
            ),
            _Label(l10n.descriptionLabel),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.taskDescriptionHint),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(l10n.categoryLabel),
                      DropdownButtonFormField<TaskCategory>(
                        initialValue: _category,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.navy,
                        ),
                        items: [
                          for (final category in TaskCategory.values)
                            DropdownMenuItem(
                              value: category,
                              child: Text(
                                FormatUtils.taskCategory(l10n, category.name),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(l10n.deadline),
                      _DeadlineField(
                        label: TaskDateUtils.pickerLabel(context, _deadline),
                        error: _deadlineError,
                        onTap: _pickDeadline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Label(l10n.priority),
            Row(
              children: [
                for (final priority in TaskPriority.values.reversed) ...[
                  if (priority != TaskPriority.low) const SizedBox(width: 8),
                  Expanded(
                    child: _PriorityOption(
                      label: FormatUtils.priority(l10n, priority),
                      color: FormatUtils.priorityColor(priority),
                      selected: _priority == priority,
                      onTap: () => setState(() => _priority = priority),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.alarm_outlined, color: AppColors.navy, size: 25),
                const SizedBox(width: 8),
                Text(
                  l10n.reminder,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.reminderSchedule,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _reminderEnabled,
                  activeTrackColor: AppColors.sageGreen,
                  onChanged: (value) =>
                      setState(() => _reminderEnabled = value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.subtasks,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addSubtask),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.skyBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIndex, newIndex) => setState(
                () => subtasks.insert(newIndex, subtasks.removeAt(oldIndex)),
              ),
              children: [
                for (var i = 0; i < subtasks.length; i++)
                  Dismissible(
                    key: ValueKey('new-subtask-$i-${subtasks[i]}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => setState(() => subtasks.removeAt(i)),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.highPriority.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                    child: _SubtaskRow(
                      index: i,
                      title: subtasks[i],
                      onAdd: _addSubtask,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _createTask,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSaving ? l10n.creatingTask : l10n.createTask,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: AppBottomNavigation.createIndex,
        onTap: (index) {
          if (index == AppBottomNavigation.createIndex) return;
          Navigator.of(context).pop(AddTaskResult(tabIndex: index));
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One of V3's Low / Medium / High pills.
class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color : AppColors.border,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Color.lerp(color, AppColors.navy, 0.75)
                      : AppColors.secondaryText,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.index,
    required this.title,
    required this.onAdd,
  });

  final int index;
  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).addSubtask,
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: AppColors.skyBlue, size: 22),
          ),
        ],
      ),
    );
  }
}

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.label,
    required this.error,
    required this.onTap,
  });

  final String label;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: error == null ? AppColors.border : errorColor,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: AppColors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error!,
              style: TextStyle(color: errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
