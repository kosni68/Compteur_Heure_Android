import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Mode',
          subtitle: 'Clair, sombre, ou automatique.',
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Clair'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Sombre'),
                icon: Icon(Icons.nightlight_round),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.settings_suggest_outlined),
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
          title: 'Couleur',
          subtitle: 'Choisis la teinte principale de l\'application.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _seedOptions
                .map(
                  (option) => _ThemeSeedChip(
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
          'Astuce: le mode sombre utilise la meme couleur mais sur un fond plus contraste.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _ThemeSeedOption {
  const _ThemeSeedOption(this.label, this.color);

  final String label;
  final Color color;
}

const List<_ThemeSeedOption> _seedOptions = [
  _ThemeSeedOption('Menthe', Color(0xFF168377)),
  _ThemeSeedOption('Corail', Color(0xFFFE6D73)),
  _ThemeSeedOption('Ocean', Color(0xFF0EA5E9)),
  _ThemeSeedOption('Ambre', Color(0xFFF59E0B)),
  _ThemeSeedOption('Indigo', Color(0xFF4F46E5)),
  _ThemeSeedOption('Sable', Color(0xFFB08968)),
  _ThemeSeedOption('Chevaux', Color(0xFF8B5E3C)),
];

class _ThemeSeedChip extends StatelessWidget {
  const _ThemeSeedChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ThemeSeedOption option;
  final bool isSelected;
  final VoidCallback onTap;

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
            option.label,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
