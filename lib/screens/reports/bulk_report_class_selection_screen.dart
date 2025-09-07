// =============================================================
// FILE: lib/screens/reports/bulk_report_class_selection_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:smart_school_assistant/screens/reports/pdf_preview_screen.dart';
import 'package:smart_school_assistant/services/pdf_service.dart';
import 'package:smart_school_assistant/utils/ranking_service.dart';

class BulkReportClassSelectionScreen extends StatelessWidget {
  const BulkReportClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class for Reports'),
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
                  onTap: () async {
                    final rankedStudents = RankingService.getRankedStudents(classSection.id);

                    if (rankedStudents.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This class has no students.')),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating bulk report PDF...')),
                    );

                    final pdfFile = await PdfApiService.generateBulkReportCards(rankedStudents);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(pdfFile: pdfFile),
                        ),
                      );
                    }
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
