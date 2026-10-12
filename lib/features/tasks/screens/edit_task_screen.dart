import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/primary_button.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({required this.task, super.key});

  final TaskModel task;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  TextEditingController? _categoryController;
  late DateTime _deadline;
  late TaskPriority _priority;
  late bool _reminderEnabled;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _deadline = widget.task.deadline;
    _priority = widget.task.priority;
    _reminderEnabled = widget.task.reminderEnabled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show built-in categories in the current language.
    _categoryController ??= TextEditingController(
      text: FormatUtils.taskCategory(
        AppLocalizations.of(context),
        widget.task.category,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController?.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Maps a typed category back to its built-in key when it matches one.
  String _categoryValue(AppLocalizations l10n) {
    final text = _categoryController!.text.trim();
    if (text.isEmpty) return TaskCategory.personal.name;
    for (final category in TaskCategory.values) {
      final label = FormatUtils.taskCategory(l10n, category.name);
      if (label.toLowerCase() == text.toLowerCase()) return category.name;
    }
    return text;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = l10n.enterTaskName);
      return;
    }
    final repository = AppScope.of(context).tasks;
    final current = repository.byId(widget.task.id) ?? widget.task;
    await repository.update(
      current.copyWith(
        title: title,
        category: _categoryValue(l10n),
        deadline: _deadline,
        priority: _priority,
        reminderEnabled: _reminderEnabled,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTask)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.taskName,
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.categoryLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_month_outlined, color: AppColors.navy),
            title: Text(l10n.deadline),
            subtitle: Text(
              '${TaskDateUtils.dueDay(context, _deadline, withYear: true)} · '
              '${TaskDateUtils.time(context, _deadline)}',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
            onTap: _selectDeadline,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: InputDecoration(labelText: l10n.priority),
            items: [
              for (final priority in TaskPriority.values)
                DropdownMenuItem(
                  value: priority,
                  child: Text(FormatUtils.priority(l10n, priority)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminder),
            subtitle: Text(l10n.reminderSchedule),
            value: _reminderEnabled,
            activeTrackColor: AppColors.sageGreen,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
