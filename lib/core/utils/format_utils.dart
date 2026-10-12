import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/community_model.dart';
import '../../models/post_model.dart';
import '../../models/task_model.dart';
import '../theme/app_theme.dart';

abstract final class FormatUtils {
  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// e.g. "2 Apr 2025, 23:59"
  static String dateTime(BuildContext context, DateTime value) =>
      DateFormat('d MMM yyyy, HH:mm', _locale(context)).format(value);

  /// e.g. "2 Apr 2025"
  static String date(BuildContext context, DateTime value) =>
      DateFormat('d MMM yyyy', _locale(context)).format(value);

  /// e.g. "April 2025"
  static String monthYear(BuildContext context, DateTime value) =>
      DateFormat('MMMM yyyy', _locale(context)).format(value);

  /// Short weekday names, starting on Monday or Sunday.
  static List<String> weekdays(
    BuildContext context, {
    bool mondayFirst = true,
  }) {
    final format = DateFormat('E', _locale(context));
    // 1 Jan 2024 was a Monday; 31 Dec 2023 a Sunday.
    final first = mondayFirst ? DateTime(2024, 1, 1) : DateTime(2023, 12, 31);
    return [
      for (var i = 0; i < 7; i++) format.format(first.add(Duration(days: i))),
    ];
  }

  static String timeAgo(BuildContext context, DateTime value) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return date(context, value);
  }

  /// Compact counts like "1.2k".
  static String compact(BuildContext context, int value) =>
      NumberFormat.compact(locale: _locale(context)).format(value);

  static String priority(AppLocalizations l10n, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => l10n.priorityHigh,
      TaskPriority.medium => l10n.priorityMedium,
      TaskPriority.low => l10n.priorityLow,
    };
  }

  /// Display name for a stored task category; custom text is shown as-is.
  static String taskCategory(AppLocalizations l10n, String category) {
    final known = TaskCategory.values.where((c) => c.name == category);
    if (known.isEmpty) return category;
    return switch (known.first) {
      TaskCategory.academic => l10n.categoryAcademic,
      TaskCategory.project => l10n.categoryProject,
      TaskCategory.meeting => l10n.categoryMeeting,
      TaskCategory.presentation => l10n.categoryPresentation,
      TaskCategory.personal => l10n.categoryPersonal,
      TaskCategory.quiz => l10n.categoryQuiz,
      TaskCategory.examination => l10n.categoryExamination,
    };
  }

  static Color priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => AppColors.highPriority,
      TaskPriority.medium => AppColors.mediumPriority,
      TaskPriority.low => AppColors.lowPriority,
    };
  }

  static String postType(AppLocalizations l10n, PostType type) {
    return switch (type) {
      PostType.discussion => l10n.postTypeDiscussion,
      PostType.question => l10n.postTypeQuestion,
      PostType.assignment => l10n.postTypeAssignment,
    };
  }

  static Color postTypeColor(PostType type) {
    return switch (type) {
      PostType.discussion => AppColors.skyBlue,
      PostType.question => const Color(0xFF9B87D9),
      PostType.assignment => AppColors.mediumPriority,
    };
  }

  static String category(AppLocalizations l10n, CommunityCategory category) {
    return switch (category) {
      CommunityCategory.course => l10n.categoryCourse,
      CommunityCategory.major => l10n.categoryMajor,
      CommunityCategory.general => l10n.categoryGeneral,
    };
  }
}
