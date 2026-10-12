import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small rounded label, used for priorities and post types.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.lerp(color, AppColors.navy, 0.35),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Circle avatar showing a person's initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.name, this.radius = 20, super.key});

  final String name;
  final double radius;

  static const _colors = [
    AppColors.skyBlue,
    AppColors.sageGreen,
    AppColors.mediumPriority,
    AppColors.highPriority,
    Color(0xFF9B87D9),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    final color = _colors[name.hashCode.abs() % _colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.25),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.trailing,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// When set, the field is read-only and acts as a button.
  final VoidCallback? onTap;
  final bool autofocus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: onTap != null,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.secondaryText),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

/// A horizontal row of single-select chips.
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
                selectedColor: AppColors.brand,
                backgroundColor: AppColors.white,
                side: BorderSide(color: AppColors.border),
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: value == selected ? Colors.white : AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Form section label used above fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
