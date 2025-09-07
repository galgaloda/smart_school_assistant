// =============================================================
// FILE: lib/screens/reports/id_card_generator_screen.dart (NEW FILE)
// =============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:smart_school_assistant/screens/reports/pdf_preview_screen.dart';
import 'package:smart_school_assistant/services/pdf_service.dart';

class IdCardGeneratorScreen extends StatefulWidget {
  final ClassSection classSection;
  const IdCardGeneratorScreen({super.key, required this.classSection});

  @override
  State<IdCardGeneratorScreen> createState() => _IdCardGeneratorScreenState();
}

class _IdCardGeneratorScreenState extends State<IdCardGeneratorScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(Student student) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        student.photoPath = image.path;
        student.save(); // Save the updated student object to Hive
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepare ID Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final studentsInClass = Hive.box<Student>('students')
                  .values
                  .where((s) => s.classSectionId == widget.classSection.id)
                  .toList();

              if (studentsInClass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No students in this class to generate cards for.')),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating ID Cards PDF...')),
              );

              final pdfFile = await PdfApiService.generateIdCards(studentsInClass, widget.classSection);

              if (!mounted) return;

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(pdfFile: pdfFile),
                ),
              );
            },
            tooltip: 'Generate PDF',
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Student>('students').listenable(),
        builder: (context, Box<Student> box, _) {
          final studentsInClass = box.values
              .where((s) => s.classSectionId == widget.classSection.id)
              .toList();

          if (studentsInClass.isEmpty) {
            return const Center(child: Text('No students in this class.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: studentsInClass.length,
            itemBuilder: (context, index) {
              final student = studentsInClass[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: student.photoPath != null
                        ? FileImage(File(student.photoPath!))
                        : null,
                    child: student.photoPath == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(student.fullName),
                  subtitle: Text(student.photoPath == null ? 'No photo added' : 'Photo added'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: () => _pickImage(student),
                    tooltip: 'Add/Change Photo',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
