import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../theme/backgrounds.dart';
import '../utils/format_utils.dart';
import '../widgets/app_background.dart';
import '../widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _objectiveController = TextEditingController();
  final FocusNode _objectiveFocus = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _objectiveController.dispose();
    _objectiveFocus.dispose();
    super.dispose();
  }

  void _syncFromController() {
    if (!mounted) {
      return;
    }
    if (_objectiveFocus.hasFocus) {
      return;
    }
    final l10n = context.l10n;
    _objectiveController.text = formatDecimalHoursFromMinutes(
      widget.controller.data.targetMinutes,
      decimalSeparator: l10n.decimalSeparator,
    );
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _saveObjective() {
    final minutes =
        parseDecimalHoursToMinutes(_objectiveController.text, allowZero: false);
    if (minutes == null) {
      setState(() {
        _errorMessage = context.l10n.settingsInvalidTarget;
      });
      return;
    }

    final data = widget.controller.data;
    final updated = data.copyWith(targetMinutes: minutes);
    unawaited(widget.controller.update(updated));
    setState(() {
      _errorMessage = null;
    });
  }

  void _updateLanguage(String code) {
    final data = widget.controller.data;
    if (data.localeCode == code) {
      return;
    }
    final updated = data.copyWith(localeCode: code);
    unawaited(widget.controller.update(updated));
  }

  void _updateBackground(String id) {
    final data = widget.controller.data;
    if (data.backgroundId == id) {
      return;
    }
    final updated = data.copyWith(backgroundId: id);
    unawaited(widget.controller.update(updated));
  }

  Widget _languageChip({
    required String label,
    required String value,
    required bool selected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _updateLanguage(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final l10n = context.l10n;
    final selectedLanguage = _languageCodes.contains(data.localeCode)
        ? data.localeCode
        : 'fr';
    final selectedBackground = kBackgroundIds.contains(data.backgroundId)
        ? data.backgroundId
        : kDefaultBackgroundId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: l10n.settingsDailyTargetTitle,
          subtitle: l10n.settingsDailyTargetSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _objectiveController,
                focusNode: _objectiveFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.settingsTargetLabel,
                  hintText: l10n.settingsTargetHint,
                  suffixText: 'h',
                ),
                onSubmitted: (_) => _saveObjective(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveObjective,
                icon: const Icon(Icons.save),
                label: Text(l10n.settingsSave),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.settingsLanguageTitle,
          subtitle: l10n.settingsLanguageSubtitle,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _languageChip(
                label: l10n.settingsLanguageSystem,
                value: 'system',
                selected: selectedLanguage == 'system',
              ),
              _languageChip(
                label: l10n.settingsLanguageFrench,
                value: 'fr',
                selected: selectedLanguage == 'fr',
              ),
              _languageChip(
                label: l10n.settingsLanguageEnglish,
                value: 'en',
                selected: selectedLanguage == 'en',
              ),
              _languageChip(
                label: l10n.settingsLanguageItalian,
                value: 'it',
                selected: selectedLanguage == 'it',
              ),
              _languageChip(
                label: l10n.settingsLanguageGerman,
                value: 'de',
                selected: selectedLanguage == 'de',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.settingsBackgroundTitle,
          subtitle: l10n.settingsBackgroundSubtitle,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kBackgroundIds
                .map(
                  (id) => _BackgroundOptionTile(
                    id: id,
                    label: backgroundLabel(l10n, id),
                    isSelected: selectedBackground == id,
                    onTap: () => _updateBackground(id),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _BackgroundOptionTile extends StatelessWidget {
  const _BackgroundOptionTile({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    AppBackground(
                      backgroundId: id,
                      showGlows: false,
                      child: const SizedBox.expand(),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _languageCodes = [
  'system',
  'fr',
  'en',
  'it',
  'de',
];
