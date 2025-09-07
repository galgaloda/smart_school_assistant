import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../utils/ranking_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  ClassSection? _selectedClass;
  bool _isLoading = true;

  // Analytics data
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _totalSubjects = 0;
  int _totalTeachers = 0;
  double _averageAttendance = 0.0;
  double _averageGrade = 0.0;

  // Chart data
  List<PieChartSectionData> _gradeDistribution = [];
  List<BarChartGroupData> _subjectPerformance = [];
  List<LineChartBarData> _attendanceTrend = [];
  List<PieChartSectionData> _classDistribution = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    // Load basic statistics
    final studentsBox = Hive.box<Student>('students');
    final classesBox = Hive.box<ClassSection>('class_sections');
    final subjectsBox = Hive.box<Subject>('subjects');
    final teachersBox = Hive.box<Teacher>('teachers');
    final attendanceBox = Hive.box<AttendanceRecord>('attendance_records');
    final scoresBox = Hive.box<Score>('scores');

    _totalStudents = studentsBox.length;
    _totalClasses = classesBox.length;
    _totalSubjects = subjectsBox.length;
    _totalTeachers = teachersBox.length;

    // Calculate average attendance
    if (attendanceBox.isNotEmpty) {
      final totalAttendance = attendanceBox.values.length;
      final presentCount = attendanceBox.values
          .where((a) => a.status == 'Present')
          .length;
      _averageAttendance = totalAttendance > 0 ? (presentCount / totalAttendance) * 100 : 0.0;
    }

    // Calculate average grade
    if (scoresBox.isNotEmpty) {
      final totalScore = scoresBox.values
          .map((s) => s.marks)
          .reduce((a, b) => a + b);
      _averageGrade = scoresBox.isNotEmpty ? totalScore / scoresBox.length : 0.0;
    }

    // Load chart data
    await _loadGradeDistribution();
    await _loadSubjectPerformance();
    await _loadAttendanceTrend();
    await _loadClassDistribution();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadGradeDistribution() async {
    final scoresBox = Hive.box<Score>('scores');
    final studentsBox = Hive.box<Student>('students');

    Map<String, int> gradeCounts = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};

    for (final student in studentsBox.values) {
      final studentScores = scoresBox.values
          .where((s) => s.studentId == student.id)
          .toList();

      if (studentScores.isNotEmpty) {
        final average = studentScores
            .map((s) => s.marks)
            .reduce((a, b) => a + b) / studentScores.length;

        String grade;
        if (average >= 90) grade = 'A';
        else if (average >= 80) grade = 'B';
        else if (average >= 70) grade = 'C';
        else if (average >= 60) grade = 'D';
        else grade = 'F';

        gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
      }
    }

    _gradeDistribution = gradeCounts.entries.map((entry) {
      final colors = {
        'A': Colors.green,
        'B': Colors.blue,
        'C': Colors.orange,
        'D': Colors.purple,
        'F': Colors.red,
      };

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        color: colors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Future<void> _loadSubjectPerformance() async {
    final scoresBox = Hive.box<Score>('scores');
    final subjectsBox = Hive.box<Subject>('subjects');

    Map<String, double> subjectAverages = {};

    for (final subject in subjectsBox.values) {
      final subjectScores = scoresBox.values
          .where((s) => s.subjectId == subject.id)
          .toList();

      if (subjectScores.isNotEmpty) {
        final average = subjectScores
            .map((s) => s.marks)
            .reduce((a, b) => a + b) / subjectScores.length;
        subjectAverages[subject.name] = average;
      }
    }

    _subjectPerformance = subjectAverages.entries.map((entry) {
      return BarChartGroupData(
        x: subjectAverages.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.indigo,
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  Future<void> _loadAttendanceTrend() async {
    final attendanceBox = Hive.box<AttendanceRecord>('attendance_records');

    // Group by date and calculate attendance rate
    Map<String, List<AttendanceRecord>> attendanceByDate = {};

    for (final record in attendanceBox.values) {
      final dateKey = record.date.toString().split(' ')[0];
      attendanceByDate[dateKey] = (attendanceByDate[dateKey] ?? [])..add(record);
    }

    List<FlSpot> spots = [];
    int index = 0;

    for (final date in attendanceByDate.keys.take(7)) {
      final records = attendanceByDate[date]!;
      final presentCount = records.where((r) => r.status == 'Present').length;
      final rate = records.isNotEmpty ? (presentCount / records.length) * 100 : 0.0;

      spots.add(FlSpot(index.toDouble(), rate));
      index++;
    }

    _attendanceTrend = [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Colors.green,
        barWidth: 3,
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(show: true),
      ),
    ];
  }

  Future<void> _loadClassDistribution() async {
    final studentsBox = Hive.box<Student>('students');
    final classesBox = Hive.box<ClassSection>('class_sections');

    Map<String, int> classCounts = {};

    for (final classSection in classesBox.values) {
      final studentCount = studentsBox.values
          .where((s) => s.classSectionId == classSection.id)
          .length;
      classCounts[classSection.name] = studentCount;
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];

    _classDistribution = classCounts.entries.map((entry) {
      final index = classCounts.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        color: colors[index % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  _buildKPICards(),

                  const SizedBox(height: 24),

                  // Class Selection
                  _buildClassSelector(),

                  const SizedBox(height: 24),

                  // Charts Section
                  _buildChartsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildKPICards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildKPICard('Total Students', _totalStudents.toString(), Icons.people, Colors.blue),
        _buildKPICard('Total Classes', _totalClasses.toString(), Icons.class_, Colors.green),
        _buildKPICard('Average Attendance', '${_averageAttendance.toStringAsFixed(1)}%', Icons.check_circle, Colors.orange),
        _buildKPICard('Average Grade', '${_averageGrade.toStringAsFixed(1)}%', Icons.grade, Colors.purple),
        _buildKPICard('Total Subjects', _totalSubjects.toString(), Icons.book, Colors.teal),
        _buildKPICard('Total Teachers', _totalTeachers.toString(), Icons.person, Colors.indigo),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class for Detailed Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
              builder: (context, Box<ClassSection> box, _) {
                final classes = box.values.toList();

                if (classes.isEmpty) {
                  return const Text('No classes available');
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

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Visualizations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),

        // Grade Distribution Chart
        _buildChartCard(
          'Grade Distribution',
          'Overall grade distribution across all students',
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _gradeDistribution,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subject Performance Chart
        _buildChartCard(
          'Subject Performance',
          'Average performance by subject',
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _subjectPerformance,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final subjects = Hive.box<Subject>('subjects').values.toList();
                        if (value.toInt() < subjects.length) {
                          return Text(
                            subjects[value.toInt()].name,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Attendance Trend Chart
        _buildChartCard(
          'Attendance Trend (Last 7 Days)',
          'Daily attendance rate over the past week',
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: _attendanceTrend,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() < days.length) {
                          return Text(days[value.toInt()]);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Class Distribution Chart
        _buildChartCard(
          'Class Distribution',
          'Number of students per class',
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _classDistribution,
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, String subtitle, Widget chart) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }
}