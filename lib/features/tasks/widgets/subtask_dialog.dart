import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Asks for a subtask title. Returns null when cancelled.
Future<String?> showAddSubtaskDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _AddSubtaskDialog(),
  );
}

class _AddSubtaskDialog extends StatefulWidget {
  const _AddSubtaskDialog();

  @override
  State<_AddSubtaskDialog> createState() => _AddSubtaskDialogState();
}

class _AddSubtaskDialogState extends State<_AddSubtaskDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterSubtaskError);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addSubtask),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.subtaskLabel,
          hintText: l10n.enterSubtaskHint,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }
}
