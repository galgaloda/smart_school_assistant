// =============================================================
// FILE: lib/services/pdf_service.dart (UPDATED)
// =============================================================
import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_school_assistant/models.dart';
import 'package:collection/collection.dart';
import 'package:smart_school_assistant/utils/ranking_service.dart';

class PdfApiService {
  // --- REFACTORED to use a helper for single report generation ---
  static Future<Uint8List> generateStudentReport(Student student, StudentRank rank) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return _buildReportCardPage(student, rank);
        },
      ),
    );
    return pdf.save();
  }

  // --- NEW METHOD for generating a PDF with all reports ---
  static Future<Uint8List> generateBulkReportCards(List<StudentRank> rankedStudents) async {
    final pdf = pw.Document();

    for (final studentRank in rankedStudents) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return _buildReportCardPage(studentRank.student, studentRank);
          },
        ),
      );
    }
    return pdf.save();
  }

  // --- NEW HELPER WIDGET to avoid code duplication ---
  static pw.Widget _buildReportCardPage(Student student, StudentRank rank) {
    final scoresBox = Hive.box<Score>('scores');
    final subjectsBox = Hive.box<Subject>('subjects');
    final studentScores = scoresBox.values.where((s) => s.studentId == student.id).toList();
    final scoresBySubject = groupBy(studentScores, (Score s) => s.subjectId);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Student Report Card', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Text('Student Name: ${student.fullName}', style: const pw.TextStyle(fontSize: 18)),
        pw.Text('Student ID: ${student.id}', style: const pw.TextStyle(fontSize: 18)),
        pw.Text('Class Rank: ${rank.rank}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(height: 30),

        pw.Text('Academic Performance', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['Subject', 'Average Mark'],
          data: scoresBySubject.entries.map((entry) {
            final subject = subjectsBox.values.firstWhere((s) => s.id == entry.key, orElse: () => Subject(id: '', name: 'Unknown', teacherId: ''));
            final totalMarks = entry.value.fold<double>(0, (sum, item) => sum + item.marks);
            final average = entry.value.isNotEmpty ? totalMarks / entry.value.length : 0.0;
            return [subject.name, average.toStringAsFixed(2)];
          }).toList(),
        ),
      ],
    );
  }

  // --- generateIdCards method remains the same ---
  static Future<Uint8List> generateIdCards(List<Student> students, ClassSection classSection) async {
    final pdf = pw.Document();
    const cardsPerPage = 8;
    final studentPages = students.slices(cardsPerPage).toList();

    for (var studentPage in studentPages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              children: studentPage.map((student) {
                return _buildIdCard(student, classSection);
              }).toList(),
            );
          },
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _buildIdCard(Student student, ClassSection classSection) {
    pw.ImageProvider? studentImage;
    if (student.photoPath != null) {
      final imageFile = File(student.photoPath!);
      if (imageFile.existsSync()) {
        studentImage = pw.MemoryImage(imageFile.readAsBytesSync());
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            color: PdfColors.indigo,
            child: pw.Center(
              child: pw.Text(
                'Your School Name',
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 60,
                height: 60,
                child: studentImage != null
                    ? pw.Image(studentImage, fit: pw.BoxFit.cover)
                    : pw.Container(color: PdfColors.grey300, child: pw.Center(child: pw.Text('Photo'))),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(student.fullName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('ID: ${student.id}'),
                    pw.SizedBox(height: 5),
                    pw.Text('Class: ${classSection.name}'),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
