import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../services/advanced_pdf_service.dart';
import '../utils/ranking_service.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> {
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentTask = '';
  ClassSection? _selectedClass;
  String _schoolName = 'Smart School Assistant';
  String _schoolAddress = '';
  String _schoolPhone = '';
  String _academicYear = DateTime.now().year.toString();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolPhoneController = TextEditingController();
  final TextEditingController _academicYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _schoolNameController.text = _schoolName;
    _schoolAddressController.text = _schoolAddress;
    _schoolPhoneController.text = _schoolPhone;
    _academicYearController.text = _academicYear;
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _generateAdvancedReportCard() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first')),
      );
      return;
    }

    final students = Hive.box<Student>('students')
        .values
        .where((s) => s.classSectionId == _selectedClass!.id)
        .toList();

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found in selected class')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentTask = 'Generating report cards...';
    });

    try {
      final rankedStudents = RankingService.getRankedStudents(_selectedClass!.id);

      final pdfBytes = await AdvancedPdfService.generateBulkAdvancedReports(
        rankedStudents,
        _selectedClass!,
        schoolName: _schoolName,
        schoolAddress: _schoolAddress,
        schoolPhone: _schoolPhone,
        academicYear: _academicYear,
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
            _currentTask = 'Generating report ${current} of ${total}...';
          });
        },
      );

      await _saveAndSharePdf(pdfBytes, 'advanced_report_cards_${_selectedClass!.name}.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced report cards generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report cards: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
        _progress = 0.0;
        _currentTask = '';
      });
    }
  }

  Future<void> _generateAdvancedIdCards() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first')),
      );
      return;
    }

    final students = Hive.box<Student>('students')
        .values
        .where((s) => s.classSectionId == _selectedClass!.id)
        .toList();

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found in selected class')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentTask = 'Generating ID cards...';
    });

    try {
      final pdfBytes = await AdvancedPdfService.generateAdvancedIdCards(
        students,
        _selectedClass!,
        schoolName: _schoolName,
        schoolAddress: _schoolAddress,
        schoolPhone: _schoolPhone,
        academicYear: _academicYear,
      );

      await _saveAndSharePdf(pdfBytes, 'advanced_id_cards_${_selectedClass!.name}.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced ID cards generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate ID cards: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
        _progress = 0.0;
        _currentTask = '';
      });
    }
  }

  Future<void> _generateClassAnalytics() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first')),
      );
      return;
    }

    final rankedStudents = RankingService.getRankedStudents(_selectedClass!.id);

    if (rankedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student data found for analytics')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentTask = 'Generating analytics report...';
    });

    try {
      final pdfBytes = await AdvancedPdfService.generateClassAnalyticsReport(
        _selectedClass!,
        rankedStudents,
        schoolName: _schoolName,
        academicYear: _academicYear,
      );

      await _saveAndSharePdf(pdfBytes, 'class_analytics_${_selectedClass!.name}.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class analytics report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate analytics report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
        _progress = 0.0;
        _currentTask = '';
      });
    }
  }

  Future<void> _saveAndSharePdf(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes);

    // Share the file
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Advanced Report - $fileName',
    );
  }

  void _updateSchoolInfo() {
    setState(() {
      _schoolName = _schoolNameController.text;
      _schoolAddress = _schoolAddressController.text;
      _schoolPhone = _schoolPhoneController.text;
      _academicYear = _academicYearController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School information updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isGenerating
          ? _buildProgressView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Information Section
                  _buildSchoolInfoSection(),

                  const SizedBox(height: 24),

                  // Class Selection
                  _buildClassSelectionSection(),

                  const SizedBox(height: 24),

                  // Report Generation Options
                  _buildReportOptionsSection(),

                  const SizedBox(height: 24),

                  // Features List
                  _buildFeaturesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _currentTask,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}% Complete',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _schoolNameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _schoolAddressController,
              decoration: const InputDecoration(
                labelText: 'School Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _schoolPhoneController,
              decoration: const InputDecoration(
                labelText: 'School Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _academicYearController,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateSchoolInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update School Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
              builder: (context, Box<ClassSection> box, _) {
                final classes = box.values.toList();

                if (classes.isEmpty) {
                  return const Text('No classes available. Please add a class first.');
                }

                return DropdownButtonFormField<ClassSection>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Choose Class',
                    border: OutlineInputBorder(),
                  ),
                  items: classes.map((classSection) {
                    return DropdownMenuItem(
                      value: classSection,
                      child: Text(classSection.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportButton(
              'Advanced Report Cards',
              'Generate professional report cards with photos and detailed analytics',
              Icons.assignment,
              _generateAdvancedReportCard,
            ),
            const SizedBox(height: 12),
            _buildReportButton(
              'Advanced ID Cards',
              'Create professional ID cards with photos and school branding',
              Icons.badge,
              _generateAdvancedIdCards,
            ),
            const SizedBox(height: 12),
            _buildReportButton(
              'Class Analytics Report',
              'Generate comprehensive class performance analytics',
              Icons.analytics,
              _generateClassAnalytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String title, String subtitle, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedClass != null ? onPressed : null,
        icon: Icon(icon),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('📸 Student Photos', 'Include student photos in all reports'),
            _buildFeatureItem('📊 Detailed Analytics', 'Comprehensive performance analysis'),
            _buildFeatureItem('🎨 Professional Design', 'Branded reports with school information'),
            _buildFeatureItem('📈 Grade Calculations', 'Automatic grade and ranking calculations'),
            _buildFeatureItem('📋 Attendance Tracking', 'Include attendance statistics'),
            _buildFeatureItem('🏆 Top Performers', 'Highlight outstanding students'),
            _buildFeatureItem('📱 Share & Print', 'Easy sharing and printing options'),
            _buildFeatureItem('🔒 Secure Storage', 'Safe and organized file management'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}