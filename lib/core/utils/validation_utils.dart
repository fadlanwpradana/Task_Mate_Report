import '../../l10n/app_localizations.dart';

abstract final class ValidationUtils {
  static String? requiredText(
    String? value,
    AppLocalizations l10n, {
    required String label,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired(label);
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    final requiredError = requiredText(value, l10n, label: l10n.emailLabel);
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return l10n.invalidEmail;
    }
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    final requiredError = requiredText(value, l10n, label: l10n.passwordLabel);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return l10n.passwordTooShort;
    }
    return null;
  }
}
