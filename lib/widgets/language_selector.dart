import 'package:flutter/material.dart';
import 'package:polite_translate/models/translation_state.dart';

class LanguageSelector extends StatelessWidget {
  final TranslationState state;
  final double fontSize;
  final bool compact;

  const LanguageSelector({
    super.key,
    required this.state,
    this.fontSize = 14,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value.startsWith('source:')) {
            state.setSourceLanguage(value.replaceFirst('source:', ''));
          } else if (value.startsWith('target:')) {
            state.setTargetLanguage(value.replaceFirst('target:', ''));
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(
            enabled: false,
            child: Text('Source Language', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...supportedLanguages.map((lang) => PopupMenuItem(
            value: 'source:$lang',
            child: Text(lang == state.sourceLanguage ? '✓ $lang' : lang),
          )),
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text('Target Language', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...supportedLanguages.map((lang) => PopupMenuItem(
            value: 'target:$lang',
            child: Text(lang == state.targetLanguage ? '✓ $lang' : lang),
          )),
        ],
        icon: const Icon(Icons.language),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: state.sourceLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  state.setSourceLanguage(newValue);
                }
              },
              items: supportedLanguages
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: fontSize)),
                );
              }).toList(),
              isExpanded: true,
              underline: Container(
                height: 2,
                color: const Color(0xFF2E5BFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                final temp = state.sourceLanguage;
                state.setSourceLanguage(state.targetLanguage);
                state.setTargetLanguage(temp);
              },
              child: Icon(Icons.swap_horiz, size: 20, color: Colors.white),
            ),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: state.targetLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  state.setTargetLanguage(newValue);
                }
              },
              items: supportedLanguages
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: fontSize)),
                );
              }).toList(),
              isExpanded: true,
              underline: Container(
                height: 2,
                color: const Color(0xFF2E5BFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
