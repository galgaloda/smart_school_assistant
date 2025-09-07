// =============================================================
// FILE: lib/screens/timetable/manage_periods_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class ManagePeriodsScreen extends StatelessWidget {
  const ManagePeriodsScreen({super.key});

  Future<void> _showAddPeriodDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    bool isBreak = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Period'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Period Name (e.g., Period 1)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time Slot (e.g., 8:00 - 8:40)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a time' : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Is this a break?'),
                      value: isBreak,
                      onChanged: (bool? value) {
                        setState(() {
                          isBreak = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final periodsBox = Hive.box<Period>('periods');
                      final newPeriod = Period(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        time: timeController.text.trim(),
                        isBreak: isBreak,
                      );
                      periodsBox.add(newPeriod);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Periods'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Period>('periods').listenable(),
        builder: (context, Box<Period> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No periods defined. Tap + to add one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final period = box.getAt(index)!;
              return Card(
                color: period.isBreak ? Colors.amber.shade50 : null,
                child: ListTile(
                  title: Text(period.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(period.time),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => box.deleteAt(index),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPeriodDialog(context),
        tooltip: 'Add Period',
        child: const Icon(Icons.add),
      ),
    );
  }
}
