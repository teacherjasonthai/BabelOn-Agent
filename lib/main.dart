import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants/app_theme.dart';
import 'models/translation_state.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => TranslationState(),
      child: const PoliteTranslateApp(),
    ),
  );
}

class PoliteTranslateApp extends StatelessWidget {
  const PoliteTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabelOn Agent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Allow the system to handle locale resolution for per-app language support
      localeListResolutionCallback: (locales, supportedLocales) {
        return locales?.first;
      },
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
        Locale('da', 'DK'),
        Locale('vi', 'VN'),
      ],
      home: const HomeScreen(),
    );
  }
}
