// =============================================================
// FILE: lib/screens/reports/report_generator_hub.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:smart_school_assistant/screens/reports/id_card_class_selection_screen.dart';
import 'package:smart_school_assistant/screens/reports/bulk_report_class_selection_screen.dart'; // <-- NEW IMPORT

class ReportGeneratorHub extends StatelessWidget {
  const ReportGeneratorHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Reports & Cards'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGeneratorOption(
            context: context,
            icon: Icons.badge,
            title: 'Student ID Cards',
            subtitle: 'Generate printable ID cards for a class.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IdCardClassSelectionScreen()),
              );
            },
          ),
          _buildGeneratorOption(
            context: context,
            icon: Icons.assessment,
            title: 'Student Report Cards',
            subtitle: 'Generate end-of-term report cards for a class.',
            onTap: () {
              // --- NAVIGATION IS NOW ACTIVE ---
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BulkReportClassSelectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
