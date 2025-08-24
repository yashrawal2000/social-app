
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/bootstrap.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/secure_storage_service.dart';
import 'ui/home/home_screen.dart';
import 'ui/shared/locale_selector.dart';

const _localeKey = 'selected_locale';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final code = await SecureStorageService.instance.read(_localeKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await SecureStorageService.instance.delete(_localeKey);
    } else {
      await SecureStorageService.instance.write(_localeKey, locale.languageCode);
    }
    notifyListeners();
  }
}

void main() async {
  await bootstrap(() => ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const MyApp(),
      ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
