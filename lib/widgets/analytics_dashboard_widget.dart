import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;

class AnalyticsDashboardWidget extends StatefulWidget {
  const AnalyticsDashboardWidget({super.key});

  @override
  State<AnalyticsDashboardWidget> createState() => _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState extends State<AnalyticsDashboardWidget>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Analytics data
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _totalSubjects = 0;
  int _totalTeachers = 0;
  double _averageAttendance = 0.0;
  double _averageGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isRefreshing = true);

    try {
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

      setState(() => _isRefreshing = false);
    } catch (e) {
      setState(() => _isRefreshing = false);
    }
  }

  bool _hasAnalyticsAccess() {
    final currentUser = user_role.AccessControlManager.getCurrentUser();
    if (currentUser == null) return false;

    final role = currentUser.role.toString().split('.').last.toLowerCase();
    return ['admin', 'principal', 'teacher'].contains(role);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnalyticsAccess()) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse
            Row(
              children: [
                const Icon(
                  Icons.dashboard,
                  color: Colors.indigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isRefreshing ? null : _loadAnalyticsData,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh data',
                ),
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _expandAnimation,
                  ),
                  tooltip: _isExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary statistics (always visible)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return isWide
                    ? Row(
                        children: [
                          _buildStatCard(
                            'Students',
                            _totalStudents.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Classes',
                            _totalClasses.toString(),
                            Icons.class_,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Attendance',
                            '${_averageAttendance.toStringAsFixed(1)}%',
                            Icons.check_circle,
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Avg Grade',
                            '${_averageGrade.toStringAsFixed(1)}%',
                            Icons.grade,
                            Colors.purple,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Students',
                                  _totalStudents.toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Classes',
                                  _totalClasses.toString(),
                                  Icons.class_,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Attendance',
                                  '${_averageAttendance.toStringAsFixed(1)}%',
                                  Icons.check_circle,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Avg Grade',
                                  '${_averageGrade.toStringAsFixed(1)}%',
                                  Icons.grade,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
              },
            ),

            // Detailed analytics (animated)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildDetailedAnalytics(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/analytics_dashboard');
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text('View Full Dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/analytics_dashboard');
                          },
                          icon: const Icon(Icons.analytics),
                          label: const Text('View Full Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Subjects',
                  _totalSubjects.toString(),
                  Icons.book,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  'Teachers',
                  _totalTeachers.toString(),
                  Icons.person,
                  Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Performance Insights',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildPerformanceIndicator('Attendance Rate', _averageAttendance),
          const SizedBox(height: 8),
          _buildPerformanceIndicator('Average Grade', _averageGrade),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(String label, double value) {
    final percentage = value.clamp(0.0, 100.0);
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 60
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}