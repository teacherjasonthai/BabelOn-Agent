import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/translation_state.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/listen_timer.dart';
import '../widgets/red_pill_button.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;

  final List<String> _languages = [
    'Afrikaans', 'Albanian', 'Amharic', 'Arabic', 'Armenian', 'Basque',
    'Belarusian', 'Bengali', 'Bosnian', 'Bulgarian', 'Catalan', 'Chinese',
    'Croatian', 'Czech', 'Danish', 'Dutch', 'English', 'Esperanto', 'Estonian',
    'Filipino', 'Finnish', 'French', 'Galician', 'Georgian', 'German', 'Greek',
    'Gujarati', 'Haitian', 'Hebrew', 'Hindi', 'Hungarian', 'Icelandic',
    'Indonesian', 'Irish', 'Italian', 'Japanese', 'Javanese', 'Kannada',
    'Kazakh', 'Korean', 'Kurdish', 'Kyrgyz', 'Lao', 'Latin', 'Latvian',
    'Lithuanian', 'Luxembourgish', 'Macedonian', 'Malagasy', 'Malay',
    'Malayalam', 'Maltese', 'Marathi', 'Mongolian', 'Nepali', 'Norwegian',
    'Odia', 'Polish', 'Portuguese', 'Punjabi', 'Romanian', 'Russian', 'Samoan',
    'Sanskrit', 'Serbian', 'Shona', 'Sindhi', 'Sinhala', 'Slovak', 'Slovenian',
    'Somali', 'Spanish', 'Sundanese', 'Swahili', 'Swedish', 'Tagalog', 'Tajik',
    'Tamil', 'Tatar', 'Telugu', 'Thai', 'Turkish', 'Turkmen', 'Ukrainian',
    'Urdu', 'Uyghur', 'Uzbek', 'Vietnamese', 'Welsh', 'Xhosa', 'Yiddish',
    'Yoruba', 'Zulu',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening(TranslationState state) {
    _pulseController.repeat(reverse: true);
    state.startListening();
  }

  void _stopListening(TranslationState state) {
    _pulseController.stop();
    state.stopListening();
  }

  void _showLanguagePicker(BuildContext context, bool isSource) {
    final state = Provider.of<TranslationState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accentGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    isSource ? 'Select Source Language' : 'Select Target Language',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final lang = _languages[index];
                      final isSelected = isSource
                          ? state.sourceLanguage == lang
                          : state.targetLanguage == lang;
                      return ListTile(
                        title: Text(
                          lang,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryRed
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primaryRed)
                            : null,
                        onTap: () {
                          if (isSource) {
                            state.setSourceLanguage(lang);
                          } else {
                            state.setTargetLanguage(lang);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<TranslationState>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Top section - Charcoal header
          Container(
            width: double.infinity,
            color: AppColors.charcoal,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
            child: Column(
              children: [
                // Back button and title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                    const Text(
                      'Live Translate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                // Language selector row — tappable, inside header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Source language
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showLanguagePicker(context, true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.sourceLanguage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Swap button
                      GestureDetector(
                        onTap: () {
                          final temp = state.sourceLanguage;
                          state.setSourceLanguage(state.targetLanguage);
                          state.setTargetLanguage(temp);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      // Target language
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showLanguagePicker(context, false),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.targetLanguage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Audio waveform
                SizedBox(
                  height: 64,
                  child: AudioWaveform(isListening: state.isListening),
                ),
                const SizedBox(height: 12),
                // Timer and speak button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ListenTimer(isListening: state.isListening),
                    RedPillButton(
                      label: state.isListening ? 'stop' : 'speak now',
                      isActive: state.isListening,
                      showIndicator: state.isListening,
                      onPressed: state.isListening
                          ? () => _stopListening(state)
                          : () => _startListening(state),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom section - Chat history
          Expanded(
            child: Container(
              color: Colors.white,
              child: state.chatHistory.isEmpty && state.recognizedText.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_none,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap "speak now" to start',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                      itemCount: state.chatHistory.length +
                          (state.recognizedText.isNotEmpty && !state.isTranslating ? 1 : 0) +
                          (state.isTranslating ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Chat history items
                        if (index < state.chatHistory.length) {
                          final message = state.chatHistory[index];
                          final isUser = message['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.primaryRed
                                    : AppColors.accentGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: SelectableText(
                                      message['content']!,
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!isUser) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => state.speak(message['content']!),
                                      child: const Icon(
                                        Icons.volume_up,
                                        size: 16,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        // Recognized text bubble
                        if (state.recognizedText.isNotEmpty &&
                            !state.isTranslating &&
                            index == state.chatHistory.length) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryRed,
                                  width: 1,
                                ),
                              ),
                              child: SelectableText(
                                state.recognizedText,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }

                        // Translating indicator
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BabelOn is thinking...',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}