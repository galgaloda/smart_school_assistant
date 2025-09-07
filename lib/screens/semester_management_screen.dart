import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class SemesterManagementScreen extends StatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  State<SemesterManagementScreen> createState() => _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  Future<void> _showAddSemesterDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController academicYearController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));

    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Semester'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Semester Name',
                      hintText: 'e.g., Semester 1, Semester 2',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter semester name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: academicYearController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      hintText: 'e.g., 2023-2024',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter academic year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    startDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: '${startDate.day}/${startDate.month}/${startDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: '${endDate.day}/${endDate.month}/${endDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final semestersBox = Hive.box<Semester>('semesters');
                  final newSemester = Semester(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    academicYear: academicYearController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    isActive: false, // New semesters start as inactive
                  );
                  semestersBox.add(newSemester);
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
        title: const Text('Semester Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Semester>('semesters').listenable(),
        builder: (context, Box<Semester> box, _) {
          final semesters = box.values.toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Semesters: ${semesters.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Active: ${semesters.where((s) => s.isActive).length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: semesters.isEmpty
                    ? const Center(
                        child: Text('No semesters found. Tap + to add one.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: semesters.length,
                        itemBuilder: (context, index) {
                          final semester = semesters[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: semester.isActive ? Colors.green : Colors.grey,
                                child: Text(
                                  semester.name.split(' ').last,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${semester.name} - ${semester.academicYear}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start: ${semester.startDate.day}/${semester.startDate.month}/${semester.startDate.year}'),
                                  Text('End: ${semester.endDate.day}/${semester.endDate.month}/${semester.endDate.year}'),
                                  Text('Status: ${semester.isActive ? 'Active' : 'Inactive'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      semester.isActive ? Icons.pause : Icons.play_arrow,
                                      color: semester.isActive ? Colors.orange : Colors.green,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        semester.isActive = !semester.isActive;
                                        semester.save();
                                      });
                                    },
                                    tooltip: semester.isActive ? 'Deactivate' : 'Activate',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      // TODO: Implement edit functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Edit functionality - Coming Soon')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Semester'),
                                          content: Text('Are you sure you want to delete "${semester.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                semester.delete();
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSemesterDialog(context),
        tooltip: 'Add Semester',
        child: const Icon(Icons.add),
      ),
    );
  }
}