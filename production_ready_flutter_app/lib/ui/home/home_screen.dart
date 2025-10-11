
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../shared/locale_selector.dart';
import 'security_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.helloWorld),
            const SizedBox(height: 16),
            Text(loc.welcomeUser('Manish')),
            const SizedBox(height: 16),
            Text(loc.unreadMessages(5)),
            const SizedBox(height: 24),
            const SecurityDashboard(),
            const SizedBox(height: 24),
            const LocaleSelector(),
          ],
        ),
      ),
    );
  }
}
