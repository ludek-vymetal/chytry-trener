import 'package:flutter/material.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

import 'daily_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fitnessApp),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyMenuScreen(),
                  ),
                );
              },

              child: Text(l10n.userMode),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // Navigator.push(context, ...);
              },

              child: Text(l10n.coachMode),
            ),
          ],
        ),
      ),
    );
  }
}