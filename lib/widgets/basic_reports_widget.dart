import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/firebase_service.dart';
import '../screens/reports/report_generator_hub.dart';
import '../screens/advanced_reports_screen.dart';
import '../screens/analytics_dashboard_screen.dart';

class BasicReportsWidget extends StatefulWidget {
  const BasicReportsWidget({super.key});

  @override
  State<BasicReportsWidget> createState() => _BasicReportsWidgetState();
}

class _BasicReportsWidgetState extends State<BasicReportsWidget>
    with SingleTickerProviderStateMixin {
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _recentReports = 0;
  bool _isRefreshing = false;
  bool _isExpanded = false;
  ClassSection? _selectedClass;
  String _selectedTimeFilter = 'All Time';
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  final List<String> _timeFilters = ['All Time', 'This Week', 'This Month', 'This Year'];

  // Report categories data
  final List<Map<String, dynamic>> _reportCategories = [
    {
      'title': '📊 Performance Reports',
      'reports': [
        {'title': 'Student Report Cards', 'subtitle': 'Individual student performance reports', 'icon': Icons.assignment, 'type': ReportType.basic},
        {'title': 'Class Analytics', 'subtitle': 'Comprehensive class performance analysis', 'icon': Icons.analytics, 'type': ReportType.advanced},
        {'title': 'Grade Distribution', 'subtitle': 'Visual grade distribution charts', 'icon': Icons.bar_chart, 'type': ReportType.analytics},
      ],
    },
    {
      'title': '👥 Student Management',
      'reports': [
        {'title': 'Student Lists', 'subtitle': 'Complete student directory with details', 'icon': Icons.people, 'type': ReportType.basic},
        {'title': 'Attendance Reports', 'subtitle': 'Student attendance tracking and summaries', 'icon': Icons.calendar_today, 'type': ReportType.basic},
        {'title': 'Enrollment Trends', 'subtitle': 'Student enrollment statistics over time', 'icon': Icons.trending_up, 'type': ReportType.analytics},
      ],
    },
    {
      'title': '📈 Administrative Reports',
      'reports': [
        {'title': 'School Overview', 'subtitle': 'High-level school statistics and KPIs', 'icon': Icons.school, 'type': ReportType.analytics},
        {'title': 'Resource Utilization', 'subtitle': 'Inventory and resource usage reports', 'icon': Icons.inventory, 'type': 'export'},
        {'title': 'Custom Reports', 'subtitle': 'Build custom reports with specific criteria', 'icon': Icons.build, 'type': ReportType.advanced},
      ],
    },
    {
      'title': '💾 Export & Sharing',
      'reports': [
        {'title': 'Export to PDF', 'subtitle': 'Generate PDF reports for printing/sharing', 'icon': Icons.picture_as_pdf, 'type': 'export'},
        {'title': 'Export to Excel', 'subtitle': 'Export data in spreadsheet format', 'icon': Icons.table_chart, 'type': 'export'},
        {'title': 'Share Reports', 'subtitle': 'Share reports via email or cloud storage', 'icon': Icons.share, 'type': 'export'},
      ],
    },
  ];

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
    _loadBasicStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBasicStats() async {
    setState(() => _isRefreshing = true);

    try {
      final studentsBox = Hive.box<Student>('students');
      final classesBox = Hive.box<ClassSection>('class_sections');

      // Apply filters
      var students = studentsBox.values.toList();
      if (_selectedClass != null) {
        students = students.where((s) => s.classSectionId == _selectedClass!.id).toList();
      }

      // Apply time filter
      if (_selectedTimeFilter != 'All Time') {
        final now = DateTime.now();
        DateTime filterDate;

        switch (_selectedTimeFilter) {
          case 'This Week':
            filterDate = now.subtract(const Duration(days: 7));
            break;
          case 'This Month':
            filterDate = DateTime(now.year, now.month, 1);
            break;
          case 'This Year':
            filterDate = DateTime(now.year, 1, 1);
            break;
          default:
            filterDate = DateTime(2000);
        }

        students = students.where((s) =>
          s.enrollmentDate != null && s.enrollmentDate!.isAfter(filterDate)
        ).toList();
      }

      setState(() {
        _totalStudents = students.length;
        _totalClasses = _selectedClass != null ? 1 : classesBox.length;
        _recentReports = _calculateRecentReports();
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _totalStudents = 0;
        _totalClasses = 0;
        _recentReports = 0;
        _isRefreshing = false;
      });
    }
  }

  int _calculateRecentReports() {
    // Calculate based on recent activity
    return (_totalStudents ~/ 8).clamp(0, 100);
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

  bool _hasReportAccess() {
    final currentUser = user_role.AccessControlManager.getCurrentUser();
    if (currentUser == null) return false;

    final role = currentUser.role.toString().split('.').last.toLowerCase();
    return ['admin', 'principal', 'teacher', 'staff'].contains(role);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasReportAccess()) {
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
                  Icons.assessment,
                  color: Colors.indigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isRefreshing ? null : _loadBasicStats,
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
                IconButton(
                  onPressed: () => _showReportsMenu(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More reports',
                ),
              ],
            ),

            // Filters section (animated)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildFiltersSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Statistics cards
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
                            'Reports',
                            _recentReports.toString(),
                            Icons.description,
                            Colors.orange,
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
                          _buildStatCard(
                            'Reports',
                            _recentReports.toString(),
                            Icons.description,
                            Colors.orange,
                          ),
                        ],
                      );
              },
            ),

            const SizedBox(height: 16),

            // Action buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToReports(context, ReportType.basic),
                              icon: const Icon(Icons.assignment),
                              label: const Text('Basic Reports'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToReports(context, ReportType.advanced),
                              icon: const Icon(Icons.analytics),
                              label: const Text('Advanced'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo,
                                side: const BorderSide(color: Colors.indigo),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToReports(context, ReportType.basic),
                              icon: const Icon(Icons.assignment),
                              label: const Text('Basic Reports'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToReports(context, ReportType.advanced),
                              icon: const Icon(Icons.analytics),
                              label: const Text('Advanced'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo,
                                side: const BorderSide(color: Colors.indigo),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
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
            'Filters',
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
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Time Period',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _timeFilters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTimeFilter = value);
                      _loadBasicStats();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
                  builder: (context, Box<ClassSection> box, _) {
                    final classes = box.values.toList();
                    return DropdownButtonFormField<ClassSection?>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class (Optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ...classes.map((classSection) {
                          return DropdownMenuItem(
                            value: classSection,
                            child: Text(classSection.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedClass = value);
                        _loadBasicStats();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
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

  void _showReportsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with search
              Row(
                children: [
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search reports...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 20),

              // Categorized sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _buildFilteredCategories(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 12),
        ...tiles,
      ],
    );
  }

  Widget _buildReportTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  List<Widget> _buildFilteredCategories() {
    List<Widget> widgets = [];

    for (var category in _reportCategories) {
      // Filter reports based on search query
      List<Map<String, dynamic>> filteredReports = [];
      if (_searchQuery.isEmpty) {
        filteredReports = List.from(category['reports']);
      } else {
        filteredReports = (category['reports'] as List<dynamic>).where((report) {
          final title = (report as Map<String, dynamic>)['title'].toString().toLowerCase();
          final subtitle = (report)['subtitle'].toString().toLowerCase();
          return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
        }).cast<Map<String, dynamic>>().toList();
      }

      // Only show category if it has matching reports
      if (filteredReports.isNotEmpty) {
        widgets.add(_buildCategorySection(
          category['title'],
          filteredReports.map((report) => _buildReportTile(
            report['title'],
            report['subtitle'],
            report['icon'],
            () {
              Navigator.pop(context);
              if (report['type'] == 'export') {
                _showExportOptions(context);
              } else {
                _navigateToReports(context, report['type']);
              }
            },
          )).toList(),
        ));

        widgets.add(const SizedBox(height: 24));
      }
    }

    // Remove last SizedBox if exists
    if (widgets.isNotEmpty && widgets.last is SizedBox) {
      widgets.removeLast();
    }

    return widgets;
  }

  void _navigateToReports(BuildContext context, ReportType type) {
    Widget destination;

    switch (type) {
      case ReportType.basic:
        destination = const ReportGeneratorHub();
        break;
      case ReportType.advanced:
        destination = const AdvancedReportsScreen();
        break;
      case ReportType.analytics:
        destination = const AnalyticsDashboardScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: const Text('Choose export format for your reports.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement PDF export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export feature coming soon!')),
              );
            },
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}

enum ReportType {
  basic,
  advanced,
  analytics,
}