import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../notifications/notification_service.dart';
import '../utils/format_utils.dart';
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
  final TextEditingController _notifyMinutesController =
      TextEditingController();
  final FocusNode _notifyMinutesFocus = FocusNode();
  final TextEditingController _pauseMinutesController =
      TextEditingController();
  final FocusNode _pauseMinutesFocus = FocusNode();
  String? _errorMessage;
  String? _notifyErrorMessage;
  String? _pauseErrorMessage;

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
    _notifyMinutesController.dispose();
    _notifyMinutesFocus.dispose();
    _pauseMinutesController.dispose();
    _pauseMinutesFocus.dispose();
    super.dispose();
  }

  void _syncFromController() {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    if (!_objectiveFocus.hasFocus) {
      _objectiveController.text = formatDecimalHoursFromMinutes(
        widget.controller.data.targetMinutes,
        decimalSeparator: l10n.decimalSeparator,
      );
    }
    if (!_notifyMinutesFocus.hasFocus) {
      _notifyMinutesController.text =
          widget.controller.data.notifyMinutesBefore.toString();
    }
    if (!_pauseMinutesFocus.hasFocus) {
      _pauseMinutesController.text =
          widget.controller.data.pauseReminderMinutes.toString();
    }
    if (_errorMessage != null ||
        _notifyErrorMessage != null ||
        _pauseErrorMessage != null) {
      setState(() {
        _errorMessage = null;
        _notifyErrorMessage = null;
        _pauseErrorMessage = null;
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

  void _saveNotificationMinutes() {
    final raw = _notifyMinutesController.text.trim();
    final minutes = int.tryParse(raw);
    if (minutes == null || minutes <= 0) {
      setState(() {
        _notifyErrorMessage = context.l10n.notificationsInvalid;
      });
      return;
    }
    final data = widget.controller.data;
    final updated = data.copyWith(notifyMinutesBefore: minutes);
    unawaited(widget.controller.update(updated));
    setState(() {
      _notifyErrorMessage = null;
    });
  }

  void _savePauseReminderMinutes() {
    final raw = _pauseMinutesController.text.trim();
    final minutes = int.tryParse(raw);
    if (minutes == null || minutes <= 0) {
      setState(() {
        _pauseErrorMessage = context.l10n.pauseReminderInvalid;
      });
      return;
    }
    final data = widget.controller.data;
    final updated = data.copyWith(pauseReminderMinutes: minutes);
    unawaited(widget.controller.update(updated));
    setState(() {
      _pauseErrorMessage = null;
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

  void _updateNotificationEnabled(bool value) {
    final data = widget.controller.data;
    if (data.notifyEnabled == value) {
      return;
    }
    final updated = data.copyWith(notifyEnabled: value);
    unawaited(widget.controller.update(updated));
    if (!value) {
      unawaited(NotificationService.cancelEndReminder());
    }
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
    final notificationsEnabled = data.notifyEnabled;

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
          title: l10n.notificationsTitle,
          subtitle: l10n.notificationsSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: notificationsEnabled,
                onChanged: _updateNotificationEnabled,
                title: Text(l10n.notificationsEnable),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notifyMinutesController,
                focusNode: _notifyMinutesFocus,
                enabled: notificationsEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.notificationsMinutesLabel,
                  hintText: l10n.notificationsMinutesHint,
                ),
                onSubmitted: (_) => _saveNotificationMinutes(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: notificationsEnabled ? _saveNotificationMinutes : null,
                icon: const Icon(Icons.save),
                label: Text(l10n.settingsSave),
              ),
              if (_notifyErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _notifyErrorMessage!,
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
          title: l10n.pauseReminderTitle,
          subtitle: l10n.pauseReminderSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _pauseMinutesController,
                focusNode: _pauseMinutesFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.pauseReminderMinutesLabel,
                  hintText: l10n.pauseReminderMinutesHint,
                ),
                onSubmitted: (_) => _savePauseReminderMinutes(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _savePauseReminderMinutes,
                icon: const Icon(Icons.save),
                label: Text(l10n.settingsSave),
              ),
              if (_pauseErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _pauseErrorMessage!,
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
      ],
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
