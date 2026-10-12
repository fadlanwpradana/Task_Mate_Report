import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/chat_repository.dart';
import 'chat_room_screen.dart';

/// Creates a group chat. Members are added one by one by exact email.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _members = <ChatUser>[];
  String? _emailError;
  String? _membersError;
  bool _lookingUp = false;
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    final email = _emailController.text;
    String? error;
    if (!ChatRepository.isValidEmail(email)) {
      error = l10n.invalidEmail;
    } else if (_members.any(
      (m) => m.email == ChatRepository.normalizeEmail(email),
    )) {
      error = l10n.memberAlreadyAdded;
    }
    if (error != null) return setState(() => _emailError = error);

    setState(() => _lookingUp = true);
    try {
      final user = await chat.findUserByEmail(email);
      if (!mounted) return;
      setState(() {
        if (user == null) {
          _emailError = l10n.emailNotRegistered;
        } else if (user.id == chat.meId) {
          _emailError = l10n.cannotChatWithSelf;
        } else {
          _members.add(user);
          _emailController.clear();
          _emailError = null;
          if (_members.length >= 2) _membersError = null;
        }
      });
    } catch (e) {
      debugPrint('Member lookup failed: $e');
      if (mounted) setState(() => _emailError = l10n.chatServerError);
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    final l10n = AppLocalizations.of(context);
    final validName = _formKey.currentState!.validate();
    setState(() {
      _membersError = _members.length < 2 ? l10n.pickAtLeastTwo : null;
    });
    if (!validName || _membersError != null) return;
    final chat = AppScope.of(context).chat;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _creating = true);
    try {
      final id = await chat.createGroup(
        name: _nameController.text.trim(),
        members: [..._members],
        firstMessage: _messageController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatRoomScreen(conversationId: id),
        ),
      );
    } catch (e) {
      debugPrint('Could not create group: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatServerError)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGroup)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            FieldLabel(l10n.groupName),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: l10n.groupNameHint),
              validator: (value) => ValidationUtils.requiredText(
                value,
                l10n,
                label: l10n.groupName,
              ),
            ),
            Row(
              children: [
                Expanded(child: FieldLabel(l10n.groupMembers)),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.membersSelected(_members.length),
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
            if (_members.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final member in _members)
                    InputChip(
                      avatar: InitialsAvatar(name: member.name, radius: 12),
                      label: Text(member.name),
                      onDeleted: () => setState(() => _members.remove(member)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addMember(),
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.memberEmail,
                hintText: l10n.emailHint,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: _emailError ?? _membersError,
                suffixIcon: _lookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.add,
                        onPressed: _addMember,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
              ),
            ),
            FieldLabel(l10n.firstMessageOptional),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.firstMessageHint),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.createGroup,
              icon: Icons.check_rounded,
              isLoading: _creating,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }
}
