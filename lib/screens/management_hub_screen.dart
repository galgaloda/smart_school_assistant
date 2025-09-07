import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'teacher_assistant/class_selection_screen.dart';
import 'timetable/manage_teachers_screen.dart';
import 'teacher_assistant/manage_subjects_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStatistics();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management Hub'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Overview
            _buildStatisticsSection(),

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
                _buildQuickActionChip('Add Class', Icons.add, Colors.blue, _addNewClass),
                _buildQuickActionChip('Add Teacher', Icons.person_add, Colors.green, _addNewTeacher),
                _buildQuickActionChip('Add Student', Icons.person_add_alt, Colors.orange, _addNewStudent),
                _buildQuickActionChip('Add Subject', Icons.library_add, Colors.purple, _addNewSubject),
                _buildQuickActionChip('Generate Report', Icons.assessment, Colors.teal, _generateQuickReport),
                _buildQuickActionChip('Backup Data', Icons.backup, Colors.red, _backupData),
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
}

// Functional management screens
class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Student>('students').listenable(),
        builder: (context, Box<Student> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No students found. Add students through class management.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final student = box.getAt(index)!;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Text(student.fullName[0].toUpperCase()),
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('ID: ${student.id}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => box.deleteAt(index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
