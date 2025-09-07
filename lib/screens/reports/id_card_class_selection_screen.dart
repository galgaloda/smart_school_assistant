// =============================================================
// FILE: lib/screens/reports/id_card_class_selection_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'id_card_generator_screen.dart';

class IdCardClassSelectionScreen extends StatelessWidget {
  const IdCardClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class for ID Cards'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
        builder: (context, Box<ClassSection> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No classes found.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final classSection = box.getAt(index)!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.class_, color: Colors.indigo),
                  title: Text(classSection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IdCardGeneratorScreen(classSection: classSection),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
