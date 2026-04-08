import 'package:flutter/material.dart';
import 'daily_menu_screen.dart'; // importuj ostatní obrazovky
// import 'trainer_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fitness Aplikace")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigace do uživatelského módu (jídelníček)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyMenuScreen()),
                );
              },
              child: const Text("Uživatelský mód"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigace do trenérského módu
                // Navigator.push(context, ...);
              },
              child: const Text("Trenérský mód"),
            ),
          ],
        ),
      ),
    );
  }
}