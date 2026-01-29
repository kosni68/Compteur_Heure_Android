import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/app_controller.dart';
import '../widgets/section_card.dart';
import '../utils/format_utils.dart';

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
    _objectiveController.text = formatDecimalHoursFromMinutes(
      widget.controller.data.targetMinutes,
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
        _errorMessage = 'Objectif invalide. Exemple: 8,4';
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

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final selectedLanguage = _languageOptions.any((opt) => opt.code == data.localeCode)
        ? data.localeCode
        : 'fr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Objectif journalier',
          subtitle: 'Par jour, en heures decimales (8,4 = 8h24).',
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
                decoration: const InputDecoration(
                  labelText: 'Objectif',
                  hintText: '8,4',
                  suffixText: 'h',
                ),
                onSubmitted: (_) => _saveObjective(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveObjective,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
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
          title: 'Langue',
          subtitle: 'Choisis la langue de l\'application.',
          child: SegmentedButton<String>(
            segments: _languageOptions
                .map(
                  (option) => ButtonSegment<String>(
                    value: option.code,
                    label: Text(option.label),
                    icon: Icon(option.icon),
                  ),
                )
                .toList(),
            selected: {selectedLanguage},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              _updateLanguage(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.icon,
  });

  final String code;
  final String label;
  final IconData icon;
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(code: 'system', label: 'Systeme', icon: Icons.devices_other),
  _LanguageOption(code: 'fr', label: 'Francais', icon: Icons.language),
  _LanguageOption(code: 'en', label: 'English', icon: Icons.translate),
];
