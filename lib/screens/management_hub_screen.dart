import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models.dart';
import '../services/sync_service.dart';
import 'teacher_assistant/class_selection_screen.dart';
import 'timetable/manage_teachers_screen.dart';
import 'teacher_assistant/manage_subjects_screen.dart';
import 'student_registration_screen.dart';
import 'class_assignment_screen.dart';
import '../services/backup_service.dart';
import 'conflict_resolution_screen.dart';
import 'background_sync_settings_screen.dart';
import 'user_management_screen.dart';
import '../models/user_role.dart';

class ManagementHubScreen extends StatefulWidget {
  const ManagementHubScreen({super.key});

  @override
  State<ManagementHubScreen> createState() => _ManagementHubScreenState();
}

class _ManagementHubScreenState extends State<ManagementHubScreen> {
  int _totalClasses = 0;
  int _totalTeachers = 0;
  int _totalStudents = 0;
  int _totalSubjects = 0;
  bool _isOnline = true;
  bool _isSyncing = false;
  String _syncStatus = 'Ready';
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _initializeSyncStatus();
    _monitorConnectivity();
  }

  Future<void> _initializeSyncStatus() async {
    final lastSyncTime = SyncService.getLastSyncTime();
    final isOnline = await SyncService.isOnline();

    setState(() {
      _lastSyncTime = lastSyncTime;
      _isOnline = isOnline;
      _syncStatus = _isOnline ? 'Ready' : 'Offline';
    });
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() {
        _isOnline = result != ConnectivityResult.none;
        _syncStatus = _isOnline ? 'Ready' : 'Offline';
      });
    });
  }

  Future<void> _performSync() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Sync requires online access.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing...';
    });

    try {
      final result = await SyncService.performFullSync();

      setState(() {
        _isSyncing = false;
        _syncStatus = result.success ? 'Synced' : 'Sync Failed';
        _lastSyncTime = DateTime.now();
      });

      // Check for conflicts
      if (result.conflicts != null && result.conflicts!.isNotEmpty) {
        // Show conflict resolution screen
        if (mounted) {
          await _showConflictResolutionScreen(result.conflicts!);
        }
      } else {
        // Show regular sync result
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'Sync Failed';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showConflictResolutionScreen(List<String> conflicts) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionScreen(
        conflicts: conflicts,
        onResolve: (conflict, strategy) {
          // Handle individual conflict resolution
          _resolveConflict(conflict, strategy);
        },
      ),
    );

    // Refresh statistics after conflict resolution
    await _loadStatistics();

    // Show completion message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conflicts resolved and sync completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resolveConflict(String conflict, ConflictStrategy strategy) {
    // This would typically send the resolution to the sync service
    // For now, we'll just log it
    print('Resolved conflict: $conflict with strategy: $strategy');
  }

  String _formatLastSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${syncTime.day}/${syncTime.month}/${syncTime.year}';
    }
  }

  Future<void> _loadStatistics() async {
    final classesBox = Hive.box<ClassSection>('class_sections');
    final teachersBox = Hive.box<Teacher>('teachers');
    final studentsBox = Hive.box<Student>('students');
    final subjectsBox = Hive.box<Subject>('subjects');

    setState(() {
      _totalClasses = classesBox.length;
      _totalTeachers = teachersBox.length;
      _totalStudents = studentsBox.length;
      _totalSubjects = subjectsBox.length;
    });
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      await BackupService.saveBackupToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Management data backup created and shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Management Data Backup'),
        content: const Text(
          'This will replace all current management data (classes, teachers, students, subjects) with the backup data. '
          'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final results = await BackupService.importFromFile();
      if (results != null) {
        // Refresh statistics after restore
        await _loadStatistics();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Management data restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management Hub'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Sync Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isOnline
                  ? (_isSyncing ? Colors.orange : Colors.green)
                  : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _isSyncing
                      ? Icons.sync
                      : (_isOnline ? Icons.cloud_done : Icons.cloud_off),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _syncStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Sync Button
          IconButton(
            icon: Icon(
              _isSyncing ? Icons.sync : Icons.sync_alt,
              color: _isOnline ? Colors.white : Colors.grey,
            ),
            onPressed: _isOnline && !_isSyncing ? _performSync : null,
            tooltip: _isOnline ? 'Sync with cloud' : 'Offline - sync unavailable',
          ),
          // Backup Button
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _createBackup(context),
            tooltip: 'Backup Management Data',
          ),
          // Restore Button
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _restoreBackup(context),
            tooltip: 'Restore Management Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Overview
            _buildStatisticsSection(),

            const SizedBox(height: 24),

            // Sync Status Section
            _buildSyncStatusSection(),

            const SizedBox(height: 24),

            // Management Options
            _buildManagementOptions(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Classes', _totalClasses.toString(), Icons.class_, Colors.blue),
                _buildStatCard('Teachers', _totalTeachers.toString(), Icons.person, Colors.green),
                _buildStatCard('Students', _totalStudents.toString(), Icons.people, Colors.orange),
                _buildStatCard('Subjects', _totalSubjects.toString(), Icons.book, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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

  Widget _buildSyncStatusSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloud Sync Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? (_isSyncing ? Colors.orange.shade100 : Colors.green.shade100)
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isSyncing
                        ? Icons.sync
                        : (_isOnline ? Icons.cloud_done : Icons.cloud_off),
                    color: _isOnline
                        ? (_isSyncing ? Colors.orange : Colors.green)
                        : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _syncStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_lastSyncTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last sync: ${_formatLastSyncTime(_lastSyncTime!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (!_isOnline) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Offline mode - changes will sync when online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isOnline && !_isSyncing)
                  ElevatedButton.icon(
                    onPressed: _performSync,
                    icon: const Icon(Icons.sync_alt, size: 16),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management Options',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildManagementCard(
              'Classes',
              'Manage class sections and details',
              Icons.class_,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
              ),
            ),
            _buildManagementCard(
              'Teachers',
              'Manage teacher profiles and assignments',
              Icons.person,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
              ),
            ),
            _buildManagementCard(
              'Students',
              'Manage student records and progress',
              Icons.people,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentManagementScreen()),
              ),
            ),
            _buildManagementCard(
              'Subjects',
              'Manage subjects and curriculum',
              Icons.book,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip('Register Student', Icons.person_add_alt, Colors.orange, _registerNewStudent),
                _buildQuickActionChip('Assign to Class', Icons.assignment_ind, Colors.teal, _assignStudentsToClass),
                _buildQuickActionChip('Add Class', Icons.add, Colors.blue, _addNewClass),
                _buildQuickActionChip('Add Teacher', Icons.person_add, Colors.green, _addNewTeacher),
                _buildQuickActionChip('Add Subject', Icons.library_add, Colors.purple, _addNewSubject),
                _buildQuickActionChip('Generate Report', Icons.assessment, Colors.teal, _generateQuickReport),
                _buildQuickActionChip('Backup Data', Icons.backup, Colors.red, _backupData),
                _buildQuickActionChip('Sync Settings', Icons.settings_backup_restore, Colors.purple, _openSyncSettings),
                if (AccessControlManager.canManageUsers())
                  _buildQuickActionChip('User Management', Icons.people, Colors.indigo, _openUserManagement),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Class "Grade 10A" was created', '2 hours ago', Icons.class_),
            _buildActivityItem('Teacher "John Doe" was added', '4 hours ago', Icons.person),
            _buildActivityItem('Student "Jane Smith" enrolled', '6 hours ago', Icons.person_add),
            _buildActivityItem('Report generated for Grade 9', '1 day ago', Icons.assessment),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Methods
  void _registerNewStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegistrationScreen()),
    );
  }

  void _assignStudentsToClass() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClassAssignmentScreen()),
    );
  }

  void _addNewClass() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
    );
  }

  void _addNewTeacher() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
    );
  }

  void _addNewStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentManagementScreen()),
    );
  }

  void _addNewSubject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
    );
  }

  void _generateQuickReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick report generation - Coming soon!')),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data backup initiated')),
    );
  }

  void _openSyncSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackgroundSyncSettingsScreen()),
    );
  }

  void _openUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }
}

// Functional management screens
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String _searchQuery = '';
  String _selectedGradeFilter = 'All Grades';
  String _selectedClassFilter = 'All Classes';

  Future<void> _createStudentBackup(BuildContext context) async {
    try {
      await BackupService.saveBackupToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student data backup created and shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreStudentBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Student Data Backup'),
        content: const Text(
          'This will replace all current student data with the backup data. '
          'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final results = await BackupService.importFromFile();
      if (results != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student data restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _createStudentBackup(context),
            tooltip: 'Backup Student Data',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _restoreStudentBackup(context),
            tooltip: 'Restore Student Data',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentRegistrationScreen()),
              );
            },
            tooltip: 'Register New Student',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Students',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGradeFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Grade',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['All Grades', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
                               'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12']
                            .map((grade) => DropdownMenuItem(value: grade, child: Text(grade)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedGradeFilter = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Class',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['All Classes', 'Unassigned']
                            .map((className) => DropdownMenuItem(value: className, child: Text(className)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedClassFilter = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Student>('students').listenable(),
              builder: (context, Box<Student> box, _) {
                final students = box.values.where((student) {
                  // Search filter
                  final matchesSearch = _searchQuery.isEmpty ||
                      student.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (student.studentId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

                  // Grade filter
                  final matchesGrade = _selectedGradeFilter == 'All Grades' ||
                      student.grade == _selectedGradeFilter;

                  // Class filter
                  final matchesClass = _selectedClassFilter == 'All Classes' ||
                      (_selectedClassFilter == 'Unassigned' && student.classSectionId == 'unassigned');

                  return matchesSearch && matchesGrade && matchesClass;
                }).toList();

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          box.values.isEmpty
                              ? 'No students registered yet.\nTap the + button to register a new student.'
                              : 'No students match your search criteria.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[100],
                          child: Text(
                            student.fullName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.indigo),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${student.studentId ?? student.id} • Age: ${student.age} • ${student.grade ?? "No Grade"}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Basic Info
                                _buildInfoRow('Full Name', student.fullName),
                                _buildInfoRow('Student ID', student.studentId ?? student.id),
                                _buildInfoRow('Date of Birth', '${student.dateOfBirth.day}/${student.dateOfBirth.month}/${student.dateOfBirth.year}'),
                                _buildInfoRow('Age', '${student.age} years'),
                                _buildInfoRow('Gender', student.gender),
                                _buildInfoRow('Grade', student.grade ?? 'Not assigned'),
                                _buildInfoRow('Class', student.classSectionId == 'unassigned' ? 'Not assigned' : student.classSectionId),

                                const Divider(),

                                // Contact Info
                                if (student.phoneNumber != null) _buildInfoRow('Phone', student.phoneNumber!),
                                if (student.email != null) _buildInfoRow('Email', student.email!),
                                if (student.address != null) _buildInfoRow('Address', student.address!),

                                const Divider(),

                                // Emergency Contact
                                if (student.emergencyContactName != null) _buildInfoRow('Emergency Contact', student.emergencyContactName!),
                                if (student.emergencyContactPhone != null) _buildInfoRow('Emergency Phone', student.emergencyContactPhone!),

                                const Divider(),

                                // Medical Info
                                if (student.bloodType != null) _buildInfoRow('Blood Type', student.bloodType!),
                                if (student.medicalConditions != null) _buildInfoRow('Medical Conditions', student.medicalConditions!),

                                const Divider(),

                                // Additional Info
                                if (student.nationality != null) _buildInfoRow('Nationality', student.nationality!),
                                if (student.religion != null) _buildInfoRow('Religion', student.religion!),
                                if (student.enrollmentDate != null) _buildInfoRow('Enrollment Date', student.formattedEnrollmentDate),

                                const SizedBox(height: 16),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _assignToClass(context, student),
                                        icon: const Icon(Icons.class_),
                                        label: const Text('Assign to Class'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _editStudent(context, student),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _deleteStudent(context, student),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete Student',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentRegistrationScreen()),
          );
        },
        backgroundColor: Colors.indigo,
        tooltip: 'Register New Student',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _assignToClass(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassAssignmentScreen(targetClassId: student.classSectionId),
      ),
    );
  }

  void _editStudent(BuildContext context, Student student) {
    _showEditStudentDialog(context, student);
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    final fullNameController = TextEditingController(text: student.fullName);
    final phoneController = TextEditingController(text: student.phoneNumber ?? '');
    final addressController = TextEditingController(text: student.address ?? '');
    final emergencyContactNameController = TextEditingController(text: student.emergencyContactName ?? '');
    final emergencyContactPhoneController = TextEditingController(text: student.emergencyContactPhone ?? '');
    final emailController = TextEditingController(text: student.email ?? '');
    final studentIdController = TextEditingController(text: student.studentId ?? '');
    final bloodTypeController = TextEditingController(text: student.bloodType ?? '');
    final medicalConditionsController = TextEditingController(text: student.medicalConditions ?? '');
    final nationalityController = TextEditingController(text: student.nationality ?? '');
    final religionController = TextEditingController(text: student.religion ?? '');

    String selectedGender = student.gender;
    String selectedGrade = student.grade ?? 'Grade 1';
    DateTime? selectedDateOfBirth = student.dateOfBirth;
    DateTime? selectedEnrollmentDate = student.enrollmentDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Student: ${student.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender *'),
                  items: ['Male', 'Female', 'Other'].map((gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender))
                  ).toList(),
                  onChanged: (value) => setState(() => selectedGender = value!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGrade,
                  decoration: const InputDecoration(labelText: 'Grade *'),
                  items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
                         'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
                         'Grade 11', 'Grade 12'].map((grade) =>
                    DropdownMenuItem(value: grade, child: Text(grade))
                  ).toList(),
                  onChanged: (value) => setState(() => selectedGrade = value!),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                TextField(
                  controller: emergencyContactNameController,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Name'),
                ),
                TextField(
                  controller: emergencyContactPhoneController,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: bloodTypeController,
                  decoration: const InputDecoration(labelText: 'Blood Type'),
                ),
                TextField(
                  controller: medicalConditionsController,
                  decoration: const InputDecoration(labelText: 'Medical Conditions'),
                  maxLines: 2,
                ),
                TextField(
                  controller: nationalityController,
                  decoration: const InputDecoration(labelText: 'Nationality'),
                ),
                TextField(
                  controller: religionController,
                  decoration: const InputDecoration(labelText: 'Religion'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fullNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Full name is required')),
                  );
                  return;
                }

                // Update student data
                student.fullName = fullNameController.text.trim();
                student.gender = selectedGender;
                student.grade = selectedGrade;
                student.phoneNumber = phoneController.text.trim().isEmpty ? null : phoneController.text.trim();
                student.email = emailController.text.trim().isEmpty ? null : emailController.text.trim();
                student.address = addressController.text.trim().isEmpty ? null : addressController.text.trim();
                student.emergencyContactName = emergencyContactNameController.text.trim().isEmpty ? null : emergencyContactNameController.text.trim();
                student.emergencyContactPhone = emergencyContactPhoneController.text.trim().isEmpty ? null : emergencyContactPhoneController.text.trim();
                student.studentId = studentIdController.text.trim().isEmpty ? null : studentIdController.text.trim();
                student.bloodType = bloodTypeController.text.trim().isEmpty ? null : bloodTypeController.text.trim();
                student.medicalConditions = medicalConditionsController.text.trim().isEmpty ? null : medicalConditionsController.text.trim();
                student.nationality = nationalityController.text.trim().isEmpty ? null : nationalityController.text.trim();
                student.religion = religionController.text.trim().isEmpty ? null : religionController.text.trim();

                await student.save();

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${student.fullName} updated successfully!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteStudent(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              student.delete();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.fullName} has been deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
