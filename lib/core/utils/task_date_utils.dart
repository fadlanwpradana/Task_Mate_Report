import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

abstract final class TaskDateUtils {
  static bool isOverdue(DateTime deadline, {DateTime? now}) =>
      (now ?? DateTime.now()).isAfter(deadline);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from today until [deadline] (0 = today).
  static int calendarDayOffset(DateTime deadline, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final due = DateTime(deadline.year, deadline.month, deadline.day);
    return due.difference(today).inDays;
  }

  /// "2 days left", "05h 30m left", or "3 hours overdue".
  static String countdown(
    AppLocalizations l10n,
    DateTime deadline, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (isOverdue(deadline, now: current)) {
      final overdue = current.difference(deadline);
      if (overdue.inDays > 0) return l10n.daysOverdue(overdue.inDays);
      if (overdue.inHours > 0) return l10n.hoursOverdue(overdue.inHours);
      final minutes = overdue.inMinutes < 1 ? 1 : overdue.inMinutes;
      return l10n.minutesOverdue(minutes);
    }
    final remaining = deadline.difference(current);
    if (remaining.inDays > 0) return l10n.daysLeft(remaining.inDays);
    return l10n.hoursMinutesLeft(
      remaining.inHours.toString().padLeft(2, '0'),
      remaining.inMinutes.remainder(60).toString().padLeft(2, '0'),
    );
  }

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// Clock time in the app language: "2:00 PM" or "14.00".
  static String time(BuildContext context, DateTime value) =>
      DateFormat.jm(_locale(context)).format(value);

  /// "Today", "Tomorrow", or a short date like "12 Oct".
  static String dueDay(
    BuildContext context,
    DateTime deadline, {
    bool withYear = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final offset = calendarDayOffset(deadline);
    if (offset == 0) return l10n.today;
    if (offset == 1) return l10n.tomorrow;
    return DateFormat(
      withYear ? 'd MMM yyyy' : 'd MMM',
      _locale(context),
    ).format(deadline);
  }

  /// e.g. "Oct 12 • 2:00 PM" for the deadline picker.
  static String pickerLabel(BuildContext context, DateTime value) =>
      '${DateFormat('d MMM', _locale(context)).format(value)} • '
      '${time(context, value)}';
}
