// =============================================================
// FILE: lib/screens/timetable/manage_teachers_screen.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'package:smart_school_assistant/models.dart';
import '../../services/backup_service.dart';

class ManageTeachersScreen extends StatelessWidget {
  const ManageTeachersScreen({super.key});

  Future<void> _showAddTeacherDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewTeacher),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.teachersFullName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterTeacherName;
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.save),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final teachersBox = Hive.box<Teacher>('teachers');
                  final newTeacher = Teacher(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    fullName: nameController.text.trim(),
                  );
                  teachersBox.add(newTeacher);

                  // Automatically create a data record for the new teacher
                  final recordsBox = Hive.box<DataRecord>('data_records');
                  final teacherRecord = DataRecord(
                    id: 'teacher_${newTeacher.id}_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Teacher Registration: ${newTeacher.fullName}',
                    category: 'Teacher Records',
                    content: '''
Teacher Registration Details:

Name: ${newTeacher.fullName}
Teacher ID: ${newTeacher.id}
Registration Date: ${DateTime.now().toString().split(' ')[0]}

Professional Information:
- Status: Active
- Employment Date: ${DateTime.now().toString().split(' ')[0]}

Note: Additional teacher details can be updated through the teacher management system.
                    ''',
                    priority: 'Medium',
                    status: 'Active',
                    dateCreated: DateTime.now(),
                    createdBy: 'System',
                  );
                  recordsBox.add(teacherRecord);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Teacher "${newTeacher.fullName}" registered successfully! Record created.'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTeacherBackup(BuildContext context) async {
    try {
      await BackupService.saveBackupToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher data backup created and shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreTeacherBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Teacher Data Backup'),
        content: const Text(
          'This will replace all current teacher data with the backup data. '
          'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final results = await BackupService.importFromFile();
      if (results != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher data restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageTeachers),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _createTeacherBackup(context),
            tooltip: 'Backup Teacher Data',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _restoreTeacherBackup(context),
            tooltip: 'Restore Teacher Data',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Teacher>('teachers').listenable(),
        builder: (context, Box<Teacher> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTeachersFound),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final teacher = box.getAt(index)!;
              return Card(
                child: ListTile(
                  title: Text(teacher.fullName),
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
        onPressed: () => _showAddTeacherDialog(context),
        tooltip: AppLocalizations.of(context)!.addTeacher,
        child: const Icon(Icons.add),
      ),
    );
  }
}
