import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/chat_repository.dart';
import '../services/local_chat_repository.dart';
import 'chat_room_screen.dart';
import 'create_group_screen.dart';

/// Starts a one-on-one chat from someone's exact email and a first message.
/// For privacy, there is no list of users to browse.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final id = await chat.startChat(
        email: _emailController.text,
        firstMessage: _messageController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatRoomScreen(conversationId: id),
        ),
      );
    } on StartChatException catch (e) {
      setState(() {
        _emailError = switch (e.error) {
          StartChatError.invalidEmail => l10n.invalidEmail,
          StartChatError.notFound => l10n.emailNotRegistered,
          StartChatError.self => l10n.cannotChatWithSelf,
        };
      });
    } catch (error) {
      debugPrint('Could not start chat: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatServerError)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newChat)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brand,
                  child: Icon(Icons.group_add_rounded, color: Colors.white),
                ),
                title: Text(
                  l10n.newGroup,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
              ),
            ),
            FieldLabel(l10n.recipientEmail),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                hintText: l10n.emailHint,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: _emailError,
              ),
              validator: (value) => ValidationUtils.email(value, l10n),
            ),
            FieldLabel(l10n.firstMessage),
            TextFormField(
              controller: _messageController,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.firstMessageHint),
              validator: (value) => ValidationUtils.requiredText(
                value,
                l10n,
                label: l10n.firstMessage,
              ),
            ),
            const SizedBox(height: 4),
            _Note(
              icon: Icons.lock_outline_rounded,
              text: l10n.startChatPrivacyNote,
            ),
            if (chat.isDemo) ...[
              const SizedBox(height: 8),
              _Note(
                icon: Icons.info_outline_rounded,
                text: l10n.demoEmailsHint(
                  LocalChatRepository.users.map((u) => u.email).join(', '),
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.send,
              icon: Icons.send_rounded,
              isLoading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ),
      ],
    );
  }
}
