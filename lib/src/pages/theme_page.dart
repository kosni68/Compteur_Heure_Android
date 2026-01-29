import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../widgets/section_card.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final selectedMode = data.themeMode;
    final selectedSeed = data.seedColor;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: l10n.themeModeTitle,
          subtitle: l10n.themeModeSubtitle,
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeModeLight),
                icon: const Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeModeDark),
                icon: const Icon(Icons.nightlight_round),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeModeSystem),
                icon: const Icon(Icons.settings_suggest_outlined),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (newSelection) {
              if (newSelection.isEmpty) {
                return;
              }
              final updated = data.copyWith(themeMode: newSelection.first);
              unawaited(controller.update(updated));
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.themeColorTitle,
          subtitle: l10n.themeColorSubtitle,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _seedOptions
                .map(
                  (option) => _ThemeSeedChip(
                    label: _seedLabel(option.id, l10n),
                    option: option,
                    isSelected: option.color.value == selectedSeed,
                    onTap: () {
                      final updated = data.copyWith(
                        seedColor: option.color.value,
                      );
                      unawaited(controller.update(updated));
                    },
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.themeTip,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _ThemeSeedOption {
  const _ThemeSeedOption(this.id, this.color);

  final String id;
  final Color color;
}

const List<_ThemeSeedOption> _seedOptions = [
  _ThemeSeedOption('mint', Color(0xFF168377)),
  _ThemeSeedOption('coral', Color(0xFFFE6D73)),
  _ThemeSeedOption('ocean', Color(0xFF0EA5E9)),
  _ThemeSeedOption('amber', Color(0xFFF59E0B)),
  _ThemeSeedOption('indigo', Color(0xFF4F46E5)),
  _ThemeSeedOption('sand', Color(0xFFB08968)),
];

String _seedLabel(String id, AppLocalizations l10n) {
  switch (id) {
    case 'coral':
      return l10n.colorCoral;
    case 'ocean':
      return l10n.colorOcean;
    case 'amber':
      return l10n.colorAmber;
    case 'indigo':
      return l10n.colorIndigo;
    case 'sand':
      return l10n.colorSand;
    case 'mint':
    default:
      return l10n.colorMint;
  }
}

class _ThemeSeedChip extends StatelessWidget {
  const _ThemeSeedChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  final _ThemeSeedOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.color,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: option.color.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.onPrimary)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
