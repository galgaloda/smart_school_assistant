import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_school_assistant/models.dart';
import 'package:collection/collection.dart';
import 'package:smart_school_assistant/utils/ranking_service.dart';
import 'package:intl/intl.dart';

class AdvancedPdfService {
  // Color scheme for professional reports
  static const PdfColor primaryColor = PdfColors.indigo;
  static const PdfColor secondaryColor = PdfColors.blue;
  static const PdfColor accentColor = PdfColors.amber;
  static const PdfColor textColor = PdfColors.black;
  static const PdfColor lightGray = PdfColor(0.95, 0.95, 0.95);

  /// Generate advanced student report card with photos and analytics
  static Future<Uint8List> generateAdvancedStudentReport(
    Student student,
    StudentRank rank,
    ClassSection classSection,
    {
      String schoolName = 'Smart School Assistant',
      String schoolAddress = '',
      String schoolPhone = '',
      String academicYear = '',
    }
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildAdvancedReportHeader(student, classSection, schoolName, schoolAddress, schoolPhone, academicYear),
            pw.SizedBox(height: 20),
            _buildStudentInfoSection(student, rank),
            pw.SizedBox(height: 20),
            _buildAcademicPerformanceSection(student, rank),
            pw.SizedBox(height: 20),
            _buildDetailedSubjectAnalysis(student),
            pw.SizedBox(height: 20),
            _buildAttendanceSummary(student),
            pw.SizedBox(height: 20),
            _buildTeacherCommentsSection(),
            pw.SizedBox(height: 20),
            _buildReportFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generate bulk advanced report cards
  static Future<Uint8List> generateBulkAdvancedReports(
    List<StudentRank> rankedStudents,
    ClassSection classSection,
    {
      String schoolName = 'Smart School Assistant',
      String schoolAddress = '',
      String schoolPhone = '',
      String academicYear = '',
      Function(int, int)? onProgress,
    }
  ) async {
    final pdf = pw.Document();

    for (int i = 0; i < rankedStudents.length; i++) {
      final studentRank = rankedStudents[i];
      onProgress?.call(i + 1, rankedStudents.length);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildAdvancedReportHeader(studentRank.student, classSection, schoolName, schoolAddress, schoolPhone, academicYear),
              pw.SizedBox(height: 20),
              _buildStudentInfoSection(studentRank.student, studentRank),
              pw.SizedBox(height: 20),
              _buildAcademicPerformanceSection(studentRank.student, studentRank),
              pw.SizedBox(height: 20),
              _buildDetailedSubjectAnalysis(studentRank.student),
              pw.SizedBox(height: 20),
              _buildAttendanceSummary(studentRank.student),
              pw.SizedBox(height: 20),
              _buildTeacherCommentsSection(),
              pw.SizedBox(height: 20),
              _buildReportFooter(),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Generate advanced ID cards with professional layout
  static Future<Uint8List> generateAdvancedIdCards(
    List<Student> students,
    ClassSection classSection,
    {
      String schoolName = 'Smart School Assistant',
      String schoolAddress = '',
      String schoolPhone = '',
      String academicYear = '',
    }
  ) async {
    final pdf = pw.Document();

    // Create ID cards (2 per page for better quality)
    const cardsPerPage = 2;
    final studentPages = students.slices(cardsPerPage).toList();

    for (var studentPage in studentPages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              children: studentPage.map((student) {
                return pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: _buildAdvancedIdCard(student, classSection, schoolName, schoolAddress, schoolPhone, academicYear),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Generate analytics report
  static Future<Uint8List> generateClassAnalyticsReport(
    ClassSection classSection,
    List<StudentRank> rankedStudents,
    {
      String schoolName = 'Smart School Assistant',
      String academicYear = '',
    }
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildAnalyticsHeader(classSection, schoolName, academicYear),
            pw.SizedBox(height: 20),
            _buildClassOverview(rankedStudents),
            pw.SizedBox(height: 20),
            _buildGradeDistribution(rankedStudents),
            pw.SizedBox(height: 20),
            _buildSubjectPerformanceAnalysis(classSection),
            pw.SizedBox(height: 20),
            _buildTopPerformersSection(rankedStudents),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Helper methods for building report sections

  static pw.Widget _buildAdvancedReportHeader(Student student, ClassSection classSection, String schoolName, String schoolAddress, String schoolPhone, String academicYear) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  schoolName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 5),
                if (schoolAddress.isNotEmpty)
                  pw.Text(
                    schoolAddress,
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                if (schoolPhone.isNotEmpty)
                  pw.Text(
                    'Phone: $schoolPhone',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Academic Year: $academicYear',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(40),
            ),
            child: pw.Center(
              child: pw.Text(
                'LOGO',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStudentInfoSection(Student student, StudentRank rank) {
    pw.ImageProvider? studentImage;
    if (student.photoPath != null) {
      final imageFile = File(student.photoPath!);
      if (imageFile.existsSync()) {
        studentImage = pw.MemoryImage(imageFile.readAsBytesSync());
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            height: 120,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: studentImage != null
                ? pw.Image(studentImage, fit: pw.BoxFit.cover)
                : pw.Center(
                    child: pw.Text(
                      'No Photo',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STUDENT REPORT CARD',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Divider(color: primaryColor, thickness: 2),
                pw.SizedBox(height: 10),
                _buildInfoRow('Student Name:', student.fullName),
                _buildInfoRow('Student ID:', student.id),
                _buildInfoRow('Date of Birth:', DateFormat('dd/MM/yyyy').format(student.dateOfBirth)),
                _buildInfoRow('Gender:', student.gender),
                _buildInfoRow('Class Rank:', '${rank.rank}'),
                _buildInfoRow('Overall Average:', '${rank.average.toStringAsFixed(2)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAcademicPerformanceSection(Student student, StudentRank rank) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACADEMIC PERFORMANCE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          _buildPerformanceOverview(rank),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedSubjectAnalysis(Student student) {
    final scoresBox = Hive.box<Score>('scores');
    final subjectsBox = Hive.box<Subject>('subjects');
    final assessmentsBox = Hive.box<Assessment>('assessments');

    final studentScores = scoresBox.values.where((s) => s.studentId == student.id).toList();
    final scoresBySubject = groupBy(studentScores, (Score s) => s.subjectId);

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETAILED SUBJECT ANALYSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          ...scoresBySubject.entries.map((entry) {
            final subject = subjectsBox.values.firstWhere(
              (s) => s.id == entry.key,
              orElse: () => Subject(id: '', name: 'Unknown', teacherId: ''),
            );

            final subjectScores = entry.value;
            final average = subjectScores.isNotEmpty
                ? subjectScores.map((s) => s.marks).reduce((a, b) => a + b) / subjectScores.length
                : 0.0;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    subject.name,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Average: ${average.toStringAsFixed(2)}%'),
                  pw.Text('Assessments: ${subjectScores.length}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildAttendanceSummary(Student student) {
    final attendanceBox = Hive.box<AttendanceRecord>('attendance_records');
    final studentAttendance = attendanceBox.values
        .where((a) => a.studentId == student.id)
        .toList();

    final present = studentAttendance.where((a) => a.status == 'Present').length;
    final absent = studentAttendance.where((a) => a.status == 'Absent').length;
    final late = studentAttendance.where((a) => a.status == 'Late').length;
    final total = studentAttendance.length;
    final attendanceRate = total > 0 ? (present / total * 100) : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ATTENDANCE SUMMARY',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildAttendanceStat('Present', present, PdfColors.green),
              _buildAttendanceStat('Absent', absent, PdfColors.red),
              _buildAttendanceStat('Late', late, PdfColors.orange),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Attendance Rate: ${attendanceRate.toStringAsFixed(1)}%',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAdvancedIdCard(Student student, ClassSection classSection, String schoolName, String schoolAddress, String schoolPhone, String academicYear) {
    pw.ImageProvider? studentImage;
    if (student.photoPath != null) {
      final imageFile = File(student.photoPath!);
      if (imageFile.existsSync()) {
        studentImage = pw.MemoryImage(imageFile.readAsBytesSync());
      }
    }

    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Row(
        children: [
          // Photo section
          pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(13),
                bottomLeft: pw.Radius.circular(13),
              ),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 100,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: studentImage != null
                      ? pw.Image(studentImage, fit: pw.BoxFit.cover)
                      : pw.Center(
                          child: pw.Text(
                            'Photo',
                            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'STUDENT ID',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Information section
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(15),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    student.fullName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Divider(color: PdfColors.grey),
                  pw.SizedBox(height: 5),
                  _buildIdCardInfoRow('ID:', student.id),
                  _buildIdCardInfoRow('Class:', classSection.name),
                  _buildIdCardInfoRow('Year:', academicYear),
                  pw.Spacer(),
                  if (schoolPhone.isNotEmpty)
                    pw.Text(
                      'Contact: $schoolPhone',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for building smaller components

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildIdCardInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        '$label $value',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildAttendanceStat(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              count.toString(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildPerformanceOverview(StudentRank rank) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Performance Overview',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Average', '${rank.average.toStringAsFixed(1)}%', secondaryColor),
              _buildStatCard('Rank', '${rank.rank}', accentColor),
              _buildStatCard('Grade', _calculateGrade(rank.average), primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 80,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTeacherCommentsSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEACHER COMMENTS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 20),
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Center(
              child: pw.Text(
                'Comments will be added by teachers...',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
            ),
          ),
          pw.Text(
            'Smart School Assistant',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalyticsHeader(ClassSection classSection, String schoolName, String academicYear) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLASS ANALYTICS REPORT',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            schoolName,
            style: const pw.TextStyle(
              fontSize: 18,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Class: ${classSection.name}',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Academic Year: $academicYear',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClassOverview(List<StudentRank> rankedStudents) {
    final average = rankedStudents.isNotEmpty
        ? rankedStudents.map((r) => r.average).reduce((a, b) => a + b) / rankedStudents.length
        : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLASS OVERVIEW',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          _buildInfoRow('Total Students:', rankedStudents.length.toString()),
          _buildInfoRow('Class Average:', '${average.toStringAsFixed(1)}%'),
          _buildInfoRow('Highest Score:', '${rankedStudents.isNotEmpty ? rankedStudents.first.average.toStringAsFixed(1) : '0'}%'),
          _buildInfoRow('Lowest Score:', '${rankedStudents.isNotEmpty ? rankedStudents.last.average.toStringAsFixed(1) : '0'}%'),
        ],
      ),
    );
  }

  static pw.Widget _buildGradeDistribution(List<StudentRank> rankedStudents) {
    // Simple grade distribution calculation
    final grades = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};

    for (final rank in rankedStudents) {
      final grade = _calculateGrade(rank.average);
      grades[grade] = (grades[grade] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GRADE DISTRIBUTION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          ...grades.entries.map((entry) =>
            _buildInfoRow('${entry.key} Grade:', '${entry.value} students')
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSubjectPerformanceAnalysis(ClassSection classSection) {
    // This would require more complex analysis
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SUBJECT PERFORMANCE ANALYSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          pw.Text(
            'Detailed subject analysis would be included here...',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopPerformersSection(List<StudentRank> rankedStudents) {
    final topPerformers = rankedStudents.take(5).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TOP PERFORMERS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),
          ...topPerformers.map((rank) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                '${rank.rank}. ${rank.student.fullName} - ${rank.average.toStringAsFixed(1)}%',
                style: const pw.TextStyle(fontSize: 12),
              ),
            )
          ),
        ],
      ),
    );
  }

  // Utility methods

  static String _calculateGrade(double average) {
    if (average >= 90) return 'A';
    if (average >= 80) return 'B';
    if (average >= 70) return 'C';
    if (average >= 60) return 'D';
    return 'F';
  }
}