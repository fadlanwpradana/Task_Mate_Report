import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/profile_settings.dart';

/// Body of the Profile tab, following Task Mate V3's profile page.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.accountName,
    required this.email,
    required this.isSigningOut,
    required this.onSignOut,
    this.onNameChanged,
    this.photoUrl,
    super.key,
  });

  /// Called after the user edits their name, e.g. to update the account.
  final ValueChanged<String>? onNameChanged;

  /// Name from the sign-in session, used until the user edits it.
  final String? accountName;
  final String email;
  final String? photoUrl;
  final bool isSigningOut;
  final VoidCallback onSignOut;

  static String languageName(AppLocalizations l10n, Locale locale) =>
      locale.languageCode == 'id'
      ? l10n.languageIndonesian
      : l10n.languageEnglish;

  static String appearanceName(AppLocalizations l10n, AppAppearance value) {
    return switch (value) {
      AppAppearance.light => l10n.appearanceLight,
      AppAppearance.dark => l10n.appearanceDark,
      AppAppearance.system => l10n.appearanceSystem,
    };
  }

  /// Shows a single-choice dialog and returns the picked value.
  static Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<(T, String)> options,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == current
                  ? const Icon(Icons.check, color: AppColors.skyBlue)
                  : null,
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    );
  }

  /// "Study week starts" picker; also opened from the settings button.
  static Future<void> chooseStudyWeek(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final profile = AppScope.of(context).profile;
    final monday = await _choose<bool>(
      context,
      title: l10n.studyWeekStarts,
      current: profile.weekStartsMonday,
      options: [(true, l10n.monday), (false, l10n.sunday)],
    );
    if (monday != null) await profile.setWeekStartsMonday(monday);
  }

  Future<void> _chooseAppearance(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final profile = AppScope.of(context).profile;
    final value = await _choose<AppAppearance>(
      context,
      title: l10n.appearance,
      current: profile.appearance,
      options: [
        for (final option in [
          AppAppearance.light,
          AppAppearance.dark,
          AppAppearance.system,
        ])
          (option, appearanceName(l10n, option)),
      ],
    );
    if (value != null) await profile.setAppearance(value);
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).locale;
    final locale = await _choose<String>(
      context,
      title: l10n.chooseLanguage,
      current: controller.value.languageCode,
      options: [
        for (final locale in LocaleController.supportedLocales)
          (locale.languageCode, languageName(l10n, locale)),
      ],
    );
    if (locale != null) await controller.setLocale(Locale(locale));
  }

  Future<void> _editProfile(BuildContext context, String currentName) async {
    final profile = AppScope.of(context).profile;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EditProfileDialog(
        name: currentName,
        studyProgram: profile.studyProgram,
      ),
    );
    if (result == null) return;
    await profile.updateProfile(name: result.$1, studyProgram: result.$2);
    onNameChanged?.call(result.$1);
  }

  void _showHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpFeedback),
        content: Text(l10n.helpFeedbackMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutQuestion),
        content: Text(l10n.logOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed == true) onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final profile = services.profile;
    return ListenableBuilder(
      listenable: Listenable.merge([profile, services.tasks, services.locale]),
      builder: (context, _) {
        final edited = profile.name?.trim();
        final name = edited != null && edited.isNotEmpty
            ? edited
            : (accountName == null || accountName!.trim().isEmpty)
            ? l10n.defaultProfileName
            : accountName!.trim();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              l10n.profileSubtitle,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            _ProfileCard(
              name: name,
              email: email,
              studyProgram: profile.studyProgram,
              photoUrl: photoUrl,
              streak: services.tasks.currentStreak(),
              onEdit: () => _editProfile(context, name),
            ),
            const SizedBox(height: 20),
            _SectionTitle(l10n.notificationSettings),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _SwitchRow(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.taskRemindersSetting,
                      subtitle: l10n.taskRemindersDescription,
                      value: profile.taskReminders,
                      onChanged: profile.setTaskReminders,
                    ),
                    _SwitchRow(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.weeklyEncouragement,
                      subtitle: l10n.weeklyEncouragementDescription,
                      value: profile.weeklyEncouragement,
                      onChanged: profile.setWeeklyEncouragement,
                    ),
                    _SwitchRow(
                      icon: Icons.groups_outlined,
                      title: l10n.groupUpdates,
                      subtitle: l10n.groupUpdatesDescription,
                      value: profile.groupUpdates,
                      onChanged: profile.setGroupUpdates,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(l10n.appSettings),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.access_time,
                    title: l10n.studyWeekStarts,
                    value: profile.weekStartsMonday ? l10n.monday : l10n.sunday,
                    onTap: () => chooseStudyWeek(context),
                  ),
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.appearance,
                    value: appearanceName(l10n, profile.appearance),
                    onTap: () => _chooseAppearance(context),
                  ),
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Icons.language_rounded,
                    title: l10n.language,
                    value: languageName(l10n, Localizations.localeOf(context)),
                    onTap: () => _chooseLanguage(context),
                  ),
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    title: l10n.helpFeedback,
                    onTap: () => _showHelp(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isSigningOut ? null : () => _confirmLogout(context),
                icon: isSigningOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.logOut),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.highPriority.withValues(
                    alpha: 0.18,
                  ),
                  foregroundColor: Colors.red.shade400,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.studyProgram,
    required this.photoUrl,
    required this.streak,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String studyProgram;
  final String? photoUrl;
  final int streak;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = TextStyle(color: AppColors.secondaryText, fontSize: 13);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            if (photoUrl != null)
              CircleAvatar(radius: 30, foregroundImage: NetworkImage(photoUrl!))
            else
              InitialsAvatar(name: name, radius: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                  if (studyProgram.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      studyProgram,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                  if (streak > 0) ...[
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: l10n.dayStreak(streak),
                      color: AppColors.sageGreen,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.editProfile,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: AppColors.skyBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.name, required this.studyProgram});

  final String name;
  final String studyProgram;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _nameController = TextEditingController(text: widget.name);
  late final _programController = TextEditingController(
    text: widget.studyProgram,
  );
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameEmpty);
      return;
    }
    Navigator.of(context).pop((name, _programController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _programController,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.studyProgram,
              hintText: l10n.studyProgramHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.skyBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.skyBlue, size: 20),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      secondary: _IconTile(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
      ),
      value: value,
      activeTrackColor: AppColors.sageGreen,
      onChanged: onChanged,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: _IconTile(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 14,
      endIndent: 14,
      color: AppColors.border,
    );
  }
}
