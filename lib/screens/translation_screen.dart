import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/translation_state.dart';
import '../services/vision_service.dart';
import '../widgets/language_switcher_pill.dart';

class TranslationScreen extends StatefulWidget {
  final String? onInitAction;

  const TranslationScreen({super.key, this.onInitAction});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final VisionService _visionService = VisionService();
  int _selectedTabIndex = 0;

  // Full language list
  final List<String> _languages = [
    'Afrikaans', 'Albanian', 'Amharic', 'Arabic', 'Armenian', 'Azerbaijani',
    'Basque', 'Belarusian', 'Bengali', 'Bosnian', 'Bulgarian', 'Catalan',
    'Cebuano', 'Chinese (Simplified)', 'Chinese (Traditional)', 'Corsican',
    'Croatian', 'Czech', 'Danish', 'Dutch', 'English', 'Esperanto', 'Estonian',
    'Finnish', 'French', 'Frisian', 'Galician', 'Georgian', 'German', 'Greek',
    'Gujarati', 'Haitian Creole', 'Hausa', 'Hawaiian', 'Hebrew', 'Hindi',
    'Hmong', 'Hungarian', 'Icelandic', 'Igbo', 'Indonesian', 'Irish', 'Italian',
    'Japanese', 'Javanese', 'Kannada', 'Kazakh', 'Khmer', 'Kinyarwanda',
    'Korean', 'Kurdish', 'Kyrgyz', 'Lao', 'Latin', 'Latvian', 'Lithuanian',
    'Luxembourgish', 'Macedonian', 'Malagasy', 'Malay', 'Malayalam', 'Maltese',
    'Maori', 'Marathi', 'Mongolian', 'Myanmar (Burmese)', 'Nepali', 'Norwegian',
    'Nyanja', 'Odia', 'Pashto', 'Persian', 'Polish', 'Portuguese', 'Punjabi',
    'Romanian', 'Russian', 'Samoan', 'Scots Gaelic', 'Serbian', 'Sesotho',
    'Shona', 'Sindhi', 'Sinhala', 'Slovak', 'Slovenian', 'Somali', 'Spanish',
    'Sundanese', 'Swahili', 'Swedish', 'Tagalog', 'Tajik', 'Tamil', 'Tatar',
    'Telugu', 'Thai', 'Turkish', 'Turkmen', 'Ukrainian', 'Urdu', 'Uyghur',
    'Uzbek', 'Vietnamese', 'Welsh', 'Xhosa', 'Yiddish', 'Yoruba', 'Zulu',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.onInitAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onInitAction == 'camera') {
          _handleCamera();
        } else if (widget.onInitAction == 'upload') {
          _handleUploadFile();
        }
      });
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
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

  Future<void> _processImagePath(String path) async {
    setState(() {
      _sourceController.text = "Processing image...";
    });

    try {
      final imageData = await _visionService.encodeImageToBase64(path);

      if (imageData != null && imageData['base64']!.isNotEmpty) {
        if (!mounted) return;
        final state = Provider.of<TranslationState>(context, listen: false);
        state.translateImage(imageData['base64']!, imageData['mimeType']!);
        setState(() {
          _sourceController.text = "Image sent for analysis";
        });
      } else {
        if (!mounted) return;
        setState(() {
          _sourceController.text = "Error: Could not encode image.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sourceController.text = "Error processing image: ${e.toString()}";
      });
    }
  }

  Future<void> _handleCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;
      if (photo == null) return;
      await _processImagePath(photo.path);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sourceController.text = "Camera error: ${e.toString()}";
      });
    }
  }

  Future<void> _handleUploadFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (image == null) return;
      await _processImagePath(image.path);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sourceController.text = "File error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<TranslationState>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Text Translate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textSecondary,
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Source input card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tappable source language
                          GestureDetector(
                            onTap: () => _showLanguagePicker(context, true),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: AppColors.primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.sourceLanguage,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primaryRed,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _sourceController.clear(),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sourceController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Enter text to translate...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_sourceController.text.length} characters',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.camera_alt_rounded),
                                color: AppColors.primaryRed,
                                onPressed: _handleCamera,
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.upload_file_rounded),
                                color: AppColors.primaryRed,
                                onPressed: _handleUploadFile,
                                iconSize: 20,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  state.translate(_sourceController.text);
                                  FocusScope.of(context).unfocus();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: state.isTranslating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Translate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Output card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tappable target language
                          GestureDetector(
                            onTap: () => _showLanguagePicker(context, false),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: AppColors.primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.targetLanguage,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primaryRed,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.star_outline),
                                color: AppColors.textSecondary,
                                onPressed: () {},
                                iconSize: 18,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                color: AppColors.textSecondary,
                                onPressed: () {
                                  if (state.translatedText.isNotEmpty) {
                                    Clipboard.setData(ClipboardData(text: state.translatedText));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard!'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: AppColors.primaryRed,
                                      ),
                                    );
                                  }
                                },
                                iconSize: 18,
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                color: AppColors.textSecondary,
                                onPressed: () {},
                                iconSize: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        state.translatedText.isNotEmpty
                            ? state.translatedText
                            : 'Translation will appear here...',
                        style: TextStyle(
                          color: state.translatedText.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: state.translatedText.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.translatedText.length} characters',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.accentGrey,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTab('Translation', 0),
                    _buildTab('Definitions', 1),
                    _buildTab('Synonyms', 2),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedTabIndex == 0)
                Text(
                  state.translatedText.isEmpty
                      ? 'Translate text to see translation'
                      : state.translatedText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                )
              else if (_selectedTabIndex == 1)
                const Text(
                  'Definitions coming soon',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  'Synonyms coming soon',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              // Language switcher pill
              LanguageSwitcherPill(
                sourceLanguage: state.sourceLanguage,
                targetLanguage: state.targetLanguage,
                onSwap: () {
                  final temp = state.sourceLanguage;
                  state.setSourceLanguage(state.targetLanguage);
                  state.setTargetLanguage(temp);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 2,
                  color: AppColors.primaryRed,
                )
            ],
          ),
        ),
      ),
    );
  }
}