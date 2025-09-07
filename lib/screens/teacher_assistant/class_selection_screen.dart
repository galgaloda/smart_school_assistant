import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'package:smart_school_assistant/main.dart';
import 'package:smart_school_assistant/models.dart';
import 'student_roster_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  Future<void> _showAddClassDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewClassSection),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.className,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterClassName;
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.save),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final classBox = Hive.box<ClassSection>('class_sections');
                  final newClass = ClassSection(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                  );
                  classBox.add(newClass);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectAClass),
        actions: [
          PopupMenuButton<Locale>(
            onSelected: (Locale locale) {
              appKey.currentState?.setLocale(locale);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<Locale>(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                // Temporarily disabled - still causing issues
                // const PopupMenuItem<Locale>(
                //   value: Locale('om'),
                //   child: Text('Afaan Oromoo'),
                // ),
                const PopupMenuItem<Locale>(
                  value: Locale('am'),
                  child: Text('አማርኛ'),
                ),
              ];
            },
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
        builder: (context, Box<ClassSection> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noClassesFound),
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
                  title: Text(classSection.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentRosterScreen(classSection: classSection),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context),
        tooltip: 'Add Class',
        child: const Icon(Icons.add),
      ),
    );
  }
}
