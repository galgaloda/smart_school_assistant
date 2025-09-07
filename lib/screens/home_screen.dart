import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'teacher_assistant/class_selection_screen.dart';
import 'timetable/timetable_screen.dart';
import 'reports/report_generator_hub.dart';
import 'settings_screen.dart';
import 'inventory_screen.dart';
import 'data_records_screen.dart';
import 'semester_management_screen.dart';
import 'assessment_customization_screen.dart';
import 'results_ranking_screen.dart';
import 'backup_restore_screen.dart';
import 'advanced_reports_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'management_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ClassSelectionScreen(),
    TimetableScreen(),
    ReportGeneratorHub(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _sendFeedback(BuildContext context) async {
    const String feedbackMessage =
        'Smart School Assistant Feedback:\n\n'
        'Please share your feedback about the app:\n\n'
        '• What features do you like?\n'
        '• What improvements would you suggest?\n'
        '• Any issues you encountered?\n\n'
        'Email: feedback@smartschool.com\n'
        'Version: 1.0.0';

    await Share.share(
      feedbackMessage,
      subject: 'Smart School Assistant Feedback',
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const String appLink = 'https://play.google.com/store/apps/details?id=com.example.smart_school_assistant';
    const String message = 'Check out Smart School Assistant - A comprehensive school management app!\n\nDownload now: $appLink';

    await Share.share(message, subject: 'Smart School Assistant App');
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Smart School Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      applicationLegalese: '© 2024 Smart School Assistant\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Smart School Assistant is a comprehensive school management application designed to help teachers and administrators manage students, classes, attendance, and generate reports efficiently.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Features include:\n'
          '• Student Management\n'
          '• Attendance Tracking\n'
          '• Grade Management\n'
          '• Report Generation\n'
          '• Analytics Dashboard\n'
          '• Photo Management\n'
          '• Multi-language Support',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart School Assistant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart School Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'School Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              subtitle: const Text('Dark mode, language, guide'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory Management'),
              subtitle: const Text('Manage school resources'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Data Records'),
              subtitle: const Text('School documents and records'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DataRecordsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Semester Management'),
              subtitle: const Text('Manage academic semesters'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SemesterManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Assessment Customization'),
              subtitle: const Text('Define assessments with weights'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessmentCustomizationScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Results & Rankings'),
              subtitle: const Text('View student grades and rankings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResultsRankingScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Backup and restore app data'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Advanced Reports'),
              subtitle: const Text('Professional report cards and analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvancedReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Analytics Dashboard'),
              subtitle: const Text('Visual data insights and KPIs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Management Hub'),
              subtitle: const Text('Enhanced management tools'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManagementHubScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              subtitle: const Text('Send feedback and suggestions'),
              onTap: () {
                Navigator.pop(context);
                _sendFeedback(context);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              subtitle: const Text('Share Smart School Assistant'),
              onTap: () {
                Navigator.pop(context);
                _shareApp(context);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App information and version'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.school),
            label: 'Teacher Assistant',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
      ),
    );
  }
}
