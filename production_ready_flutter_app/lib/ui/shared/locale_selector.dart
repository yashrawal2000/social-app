
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class LocaleSelector extends StatelessWidget {
  const LocaleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final current = provider.locale?.languageCode ?? 'system';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Language:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: current,
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
          ],
          onChanged: (v) {
            if (v == null || v == 'system') {
              provider.setLocale(null);
            } else {
              provider.setLocale(Locale(v));
            }
          },
        ),
      ],
    );
  }
}
