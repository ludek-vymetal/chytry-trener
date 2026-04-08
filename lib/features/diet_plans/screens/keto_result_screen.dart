import 'package:flutter/material.dart';
import '../logic/keto_calculator.dart';
import 'shopping_list_screen.dart'; // Importuj tvůj upravený shopping list

class KetoResultScreen extends StatefulWidget {
  final Map<String, double> macros;

  const KetoResultScreen({super.key, required this.macros});

  @override
  State<KetoResultScreen> createState() => _KetoResultScreenState();
}

class _KetoResultScreenState extends State<KetoResultScreen> {
  // ✅ Vygenerujeme týdenní menu hned při startu a uložíme ho do stavu
  late List<List<Map<String, String>>> weeklyMenu;
  final List<String> dny = ["Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota", "Neděle"];

  @override
  void initState() {
    super.initState();
    // Vygenerujeme 7 dní (každý den bude díky .shuffle() v kalkulačce trochu jiný)
    weeklyMenu = KetoCalculator.generateWeeklyKetoMenu(
      widget.macros['protein']!,
      widget.macros['fats']!,
      widget.macros['carbs']!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tvůj týdenní Keto plán"),
        backgroundColor: Colors.indigo[900],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Horní panel s makry
            _buildMacroHeader(),

            const SizedBox(height: 10),

            // Tlačítko pro nákupní seznam (předáváme CELÝ týden)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text("GENEROVAT NÁKUPNÍ SEZNAM", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingListScreen(
                        weeklyKetoMenu: weeklyMenu,
                        isKeto: true,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Jídelníček na celý týden:", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // ✅ Zobrazení 7 dní pod sebou (ExpansionTile jako u vln)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeklyMenu.length,
              itemBuilder: (context, dayIndex) {
                return ExpansionTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                  title: Text(dny[dayIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Zobrazit jídla"),
                  children: weeklyMenu[dayIndex].map((meal) {
                    return ListTile(
                      title: Text("${meal['label']}: ${meal['name']}"),
                      subtitle: Text(meal['description']!),
                      isThreeLine: true,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.indigo[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _macroColumn("Bílkoviny", "${widget.macros['protein']?.round()}g", Colors.blue),
          _macroColumn("Tuky", "${widget.macros['fats']?.round()}g", Colors.orange),
          _macroColumn("Sacharidy", "${widget.macros['carbs']?.round()}g", Colors.red),
        ],
      ),
    );
  }

  Widget _macroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}