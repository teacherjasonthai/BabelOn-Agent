import 'dart:convert'; // <- required for jsonEncode/jsonDecode
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


const List<String> supportedLanguages = [
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



Future<String> _fetchChatResponse(Map<String, dynamic> args) async {
  final String userMessage = args['userMessage']!;
  final List<Map<String, dynamic>> chatHistory = args['chatHistory']!;
  final String apiKey = args['apiKey']!;
  final String apiUrl = args['apiUrl']!;
  final String sourceLanguage = args['sourceLanguage']!;
  final String targetLanguage = args['targetLanguage']!;

  final List<Map<String, dynamic>> messages = [
    {
      'role': 'system',
      'content': 'You are an expert translator. Translate from $sourceLanguage to $targetLanguage. IMPORTANT: Output MUST be 100% in the target language ($targetLanguage). Do not include any characters from unintended languages (e.g., no Chinese characters in a Thai/English translation). Analyze the entire provided text block as a single unit to ensure contextual consistency; do not translate sentence-by-sentence in isolation. If the target is Thai, use polite particles (ครับ for male speakers, ค่ะ for female speakers) appropriately and natural spoken Thai; if the target is English, provide a natural, polite translation. If speaker gender is unknown, default to ครับ. Preserve tone and formality. Return only the translated text.'
    },
  ];
  messages.addAll(chatHistory);
  messages.add({'role': 'user', 'content': userMessage});

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
    body: jsonEncode({'model': 'llama-3.3-70b-versatile', 'messages': messages, 'temperature': 0.3}),
  );

  if (response.statusCode == 200) {
    if (kDebugMode) debugPrint('Chat API Response (Success): ${response.body}');
    return jsonDecode(response.body)['choices'][0]['message']['content'].trim();
  } else {
    if (kDebugMode) debugPrint('Chat API Response (Error): ${response.body}');
    throw Exception('Error: Chat API failed. ${response.statusCode}\n${response.body}');
  }
}

Future<String> _fetchGroqTranslation(Map<String, dynamic> args) async {
  final String? input = args['input'];
  final String? base64Image = args['base64Image'];
  final String mimeType = args['mimeType'] ?? 'image/jpeg';
  final apiKey = args['apiKey']!;
  final apiUrl = args['apiUrl']!;
  final String sourceLanguage = args['sourceLanguage']!;
  final String targetLanguage = args['targetLanguage']!;

  final bool isVision = base64Image != null;
  final model = isVision ? 'meta-llama/llama-4-scout-17b-16e-instruct' : 'llama-3.3-70b-versatile';

  if (kDebugMode) {
    debugPrint('Using model: $model');
    if (isVision) debugPrint('Image MIME type: $mimeType');
  }

  final List<Map<String, dynamic>> messages = [
    {
      'role': 'system',
      'content': 'You are an expert translator specializing in natural, conversational language. IMPORTANT: Output MUST be 100% in the target language ($targetLanguage). Do not include any characters from unintended languages. Analyze the entire provided text block (e.g., 3 sentences) as a single unit before translating to ensure contextual consistency across the entire block; avoid literal sentence-by-sentence translation. Always use formal, polite language appropriate for professional and business contexts. Use natural language that a native speaker would say, not word-for-word translations. Translate from $sourceLanguage to $targetLanguage. Only return the translated text.'
    },
  ];

  if (isVision) {
    messages.add({
      'role': 'user',
      'content': [
        {'type': 'text', 'text': 'Translate the text in this image from $sourceLanguage to $targetLanguage.'},
        {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}},
      ],
    });
  } else {
    messages.add({'role': 'user', 'content': input});
  }

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
    body: jsonEncode({'model': model, 'messages': messages, 'temperature': 0.3}),
  );

  if (response.statusCode == 200) {
    if (kDebugMode) debugPrint('API Response (Success): ${response.body}');
    return jsonDecode(response.body)['choices'][0]['message']['content'].trim();
  } else {
    if (kDebugMode) debugPrint('API Response (Error): ${response.body}');
    throw Exception('Error: Translation API failed. ${response.statusCode}\n${response.body}');
  }
}

class TranslationState with ChangeNotifier {
  FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  Timer? _debounceTimer;
  String? _currentRequestId;
  bool _isDisposed = false; // Guard against use-after-dispose crashes

  String _translatedText = 'BabelOn is ready';
  bool _isTranslating = false;
  final List<Map<String, String>> _chatHistory = [];
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Thai';
  String _recognizedText = '';
  bool _isListening = false;
  bool _isContinuousListening = false;
  double _confidence = 0.0;
  bool _userStoppedListening = false;

  String get translatedText => _translatedText;
  bool get isTranslating => _isTranslating;
  List<Map<String, String>> get chatHistory => _chatHistory;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  String get recognizedText => _recognizedText;
  bool get isListening => _isListening;
  bool get isContinuousListening => _isContinuousListening;
  double get confidence => _confidence;

  TranslationState() {
    _detectLocale();
    _setupTts();
  }

  void _detectLocale() {
    try {
      // Pull system language (e.g., 'da_DK' -> 'da')
      final String systemLocaleCode = Platform.localeName.split('_')[0].toLowerCase();

      // Specifically supported first-run languages
      final Map<String, String> firstRunModes = {
        'en': 'English',
        'th': 'Thai',
        'da': 'Danish',
        'vi': 'Vietnamese',
      };

      final detectedLanguage = firstRunModes[systemLocaleCode] ?? 'English';

      if (detectedLanguage != 'English') {
        // If user is Danish/Thai/Vietnamese, set that as source and English as target.
        _sourceLanguage = detectedLanguage;
        _targetLanguage = 'English';
      } else {
        // Default: English -> Thai
        _sourceLanguage = 'English';
        _targetLanguage = 'Thai';
      }

      if (kDebugMode) {
        debugPrint('System locale: $systemLocaleCode -> Detected: $detectedLanguage');
        debugPrint('Startup: $_sourceLanguage → $_targetLanguage');
      }
    } catch (e) {
      _sourceLanguage = 'English';
      _targetLanguage = 'Thai';
      if (kDebugMode) debugPrint('Locale detection failed, falling back to English: $e');
    }
  }

  // One-time TTS setup — selects Google engine on Android for natural voices.
  Future<void> _setupTts() async {
    if (_isDisposed) return;
    if (Platform.isAndroid) {
      try {
        await flutterTts.setEngine('com.google.android.tts')
            .timeout(const Duration(seconds: 2));
        if (_isDisposed) return;
        await _setBestVoice();
      } catch (e) {
        if (kDebugMode) debugPrint('TTS: Engine setup error: $e');
      }
    }

    if (_isDisposed) return;
    try {
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
    } catch (_) {}
  }

  // Hunts for the best available voice for the current target language.
  // Pass 1: prefer 'network' or 'neural' voices (high-quality, avoids wrong-
  //         language fallbacks like Vietnamese->French or Danish->robotic).
  // Pass 2: fall back to any voice that matches the target locale.
  Future<void> _setBestVoice() async {
    if (!Platform.isAndroid || _isDisposed) return;

    try {
      final raw = await flutterTts.getVoices
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (raw == null || _isDisposed) return;

      final List<dynamic> voicesList = (raw is List)
          ? raw
          : (raw is Map && raw['voices'] is List)
              ? raw['voices'] as List
              : [];

      // ── DIAGNOSTIC DUMP ─────────────────────────────────────────────────
      // Prints every voice whose locale starts with da-DK or vi-VN so we
      // can see exactly what the device exposes for those two languages.
      if (kDebugMode) {
        debugPrint('TTS: ── Full voice list (${voicesList.length} total) ──');
        for (final v in voicesList) {
          if (v is! Map) continue;
          final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
          if (locale.startsWith('da') || locale.startsWith('vi')) {
            debugPrint('TTS:  [${v["locale"]}]  ${v["name"]}');
          }
        }
        debugPrint('TTS: ────────────────────────────────────────────────────');
      }
      // ────────────────────────────────────────────────────────────────────

      final targetLocale =
          _getTtsLocaleId(_targetLanguage).toLowerCase().replaceAll('_', '-');

      // --- Pass 1a: Premium voices (neural / google / wavenet) ---
      Map<String, dynamic>? best;
      for (final v in voicesList) {
        if (v is! Map) continue;
        final name   = (v['name']   ?? '').toString().toLowerCase();
        final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
        if (locale.contains(targetLocale) &&
            (name.contains('neural') || name.contains('google') || name.contains('wavenet'))) {
          best = Map<String, dynamic>.from(v);
          break;
        }
      }

      // --- Pass 1b: Any other network voice ---
      if (best == null) {
        for (final v in voicesList) {
          if (v is! Map) continue;
          final name   = (v['name']   ?? '').toString().toLowerCase();
          final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
          if (locale.contains(targetLocale) && name.contains('network')) {
            best = Map<String, dynamic>.from(v);
            break;
          }
        }
      }

      // --- Pass 2: any voice for that locale ---
      if (best == null) {
        for (final v in voicesList) {
          if (v is! Map) continue;
          final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
          if (locale.contains(targetLocale)) {
            best = Map<String, dynamic>.from(v);
            break;
          }
        }
      }

      if (best != null && !_isDisposed) {
        await flutterTts.setVoice({
          'name':   best['name'].toString(),
          'locale': best['locale'].toString(),
        });
        if (kDebugMode) debugPrint('TTS: Selected -> ${best["name"]} (${best["locale"]})');
      } else if (kDebugMode) {
        debugPrint('TTS: No matching voice found for $targetLocale');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: Voice search error: $e');
    }
  }


  void setSourceLanguage(String language) {
    _sourceLanguage = language;
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    _targetLanguage = language;
    notifyListeners();
    // Re-select the best voice for the new language so network/neural voices
    // are loaded immediately — not just at startup.
    _setBestVoice();
  }

  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  void _handleError(String message) {
    _translatedText = message;
    if (kDebugMode) debugPrint('Error: $message');
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _userStoppedListening = false;

    bool available = await _speechToText.initialize(
      onError: (error) {
        if (kDebugMode) debugPrint('Speech recognition error: $error');
        _isListening = false;
        _recognizedText = 'Error: ${error.errorMsg}';
        notifyListeners();
      },
      onStatus: (status) {
        if (kDebugMode) debugPrint('Speech recognition status: $status');
        if ((status == 'done' || status == 'notListening') &&
            _isContinuousListening && _isListening && !_userStoppedListening) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
            if (_isListening && _isContinuousListening && !_userStoppedListening) {
              startListening();
            }
          });
        }
      },
    );

    if (!available) {
      _recognizedText = 'Speech recognition not available.';
      notifyListeners();
      return;
    }

    _isListening = true;
    _isContinuousListening = true;
    _recognizedText = 'Listening...';
    _confidence = 0.0;
    notifyListeners();

    try {
      _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _confidence = result.confidence;
          notifyListeners();

          if (result.finalResult && _recognizedText.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening && _recognizedText.isNotEmpty) {
                if (_sourceLanguage == _targetLanguage) {
                  _translatedText = _recognizedText;
                  _recognizedText = '';
                  notifyListeners();
                } else {
                  sendMessage(_recognizedText);
                  _recognizedText = '';
                  notifyListeners();
                }
                if (_isContinuousListening && !_userStoppedListening) {
                  _speechToText.listen(
                    onResult: (newResult) {
                      _recognizedText = newResult.recognizedWords;
                      _confidence = newResult.confidence;
                      notifyListeners();
                      if (newResult.finalResult && _recognizedText.isNotEmpty) {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_isListening && _recognizedText.isNotEmpty) {
                            if (_sourceLanguage == _targetLanguage) {
                              _translatedText = _recognizedText;
                              _recognizedText = '';
                              notifyListeners();
                            } else {
                              sendMessage(_recognizedText);
                              _recognizedText = '';
                              notifyListeners();
                            }
                          }
                        });
                      }
                    },
                    localeId: _getLocaleId(),
                  );
                }
              }
            });
          }
        },
        localeId: _getLocaleId(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      _isContinuousListening = false;
      _recognizedText = 'Error starting microphone.';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _userStoppedListening = true;
    _isContinuousListening = false;
    _debounceTimer?.cancel();
    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error stopping speech recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  String _getLocaleId() {
    return _getTtsLocaleId(_sourceLanguage);
  }

  // Returns the TTS locale for the given language name.
  String _getTtsLocaleId(String language) {
    switch (language) {
      case 'Thai': return 'th-TH';
      case 'Danish': return 'da-DK';
      case 'Vietnamese': return 'vi-VN';
      case 'German': return 'de-DE';
      case 'Russian': return 'ru-RU';
      case 'French': return 'fr-FR';
      case 'Japanese': return 'ja-JP';
      case 'Korean': return 'ko-KR';
      case 'Spanish': return 'es-ES';
      case 'Portuguese': return 'pt-BR';
      case 'Chinese': return 'zh-CN';
      case 'Arabic': return 'ar-SA';
      case 'Hindi': return 'hi-IN';
      case 'Indonesian': return 'id-ID';
      case 'Malay': return 'ms-MY';
      case 'Dutch': return 'nl-NL';
      case 'Italian': return 'it-IT';
      case 'Polish': return 'pl-PL';
      case 'Swedish': return 'sv-SE';
      case 'Turkish': return 'tr-TR';
      case 'Ukrainian': return 'uk-UA';
      case 'English':
      default: return 'en-US';
    }
  }

  Future<void> translate(String input) async {
    if (input.isEmpty) return;
    if (_groqApiKey.isEmpty) {
      _handleError('Error: API key not configured. Check your .env file.');
      return;
    }
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRequestId = requestId;
    _isTranslating = true;
    _translatedText = 'BabelOn is thinking...';
    notifyListeners();
    try {
      final result = await compute(_fetchGroqTranslation, {
        'input': input, 'apiKey': _groqApiKey, 'apiUrl': _apiUrl,
        'sourceLanguage': _sourceLanguage, 'targetLanguage': _targetLanguage,
      });
      if (requestId != _currentRequestId) return;
      _translatedText = result;
      notifyListeners();
      await speak(result);
    } catch (e) {
      _handleError('Error connecting to BabelOn.');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> translateImage(String base64Image, String mimeType) async {
    if (base64Image.isEmpty) return;
    if (_groqApiKey.isEmpty) {
      _handleError('Error: API key not configured. Check your .env file.');
      return;
    }
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRequestId = requestId;
    _isTranslating = true;
    _translatedText = 'Analyzing image...';
    notifyListeners();
    try {
      final result = await compute(_fetchGroqTranslation, {
        'base64Image': base64Image, 'mimeType': mimeType,
        'apiKey': _groqApiKey, 'apiUrl': _apiUrl,
        'sourceLanguage': _sourceLanguage, 'targetLanguage': _targetLanguage,
      });
      if (requestId != _currentRequestId) return;
      _translatedText = result;
      notifyListeners();
    } catch (e) {
      _handleError('Error analyzing image.');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    // Ensure we always pass a clean String to the TTS engine.
    final String utterance = text.toString().trim();
    if (utterance.isEmpty || _isDisposed) return;
    
    final wasListening = _isContinuousListening;
    if (wasListening) {
      await _speechToText.stop();
      if (_isDisposed) return;
      _isListening = false;
      notifyListeners();
    }
    
    // Safety check: Make sure the basic language is set correctly if _setBestVoice
    // wasn't active, but rely on _setBestVoice to have chosen the high-quality voice.
    await flutterTts.setLanguage(_getTtsLocaleId(_targetLanguage));
    
    if (_isDisposed) return;
    if (kDebugMode) debugPrint('TTS: speak() -> text="$utterance"');
    await flutterTts.speak(utterance);

    if (wasListening && !_userStoppedListening) {
      await Future.delayed(const Duration(seconds: 2));
      if (!_isDisposed && !_userStoppedListening) await startListening();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    if (_groqApiKey.isEmpty) {
      _handleError('Error: API key not configured. Check your .env file.');
      return;
    }
    _isTranslating = true;
    notifyListeners();
    try {
      _chatHistory.add({'role': 'user', 'content': text});
      final historyForApi = _chatHistory
          .map((msg) => {'role': msg['role']!, 'content': msg['content']!})
          .toList();
      final result = await compute(_fetchChatResponse, {
        'userMessage': text, 'chatHistory': historyForApi,
        'apiKey': _groqApiKey, 'apiUrl': _apiUrl,
        'sourceLanguage': _sourceLanguage, 'targetLanguage': _targetLanguage,
      });
      _chatHistory.add({'role': 'assistant', 'content': result});
      _translatedText = result;
      notifyListeners();
      await speak(result);
    } catch (e) {
      _handleError('Error in chat: ${e.toString()}');
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  void clearChatHistory() {
    _chatHistory.clear();
    _translatedText = 'Chat cleared';
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    flutterTts.stop();
    super.dispose();
  }
}