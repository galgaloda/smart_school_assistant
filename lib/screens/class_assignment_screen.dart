import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'student_registration_screen.dart';

class ClassAssignmentScreen extends StatefulWidget {
  final String? targetClassId;

  const ClassAssignmentScreen({super.key, this.targetClassId});

  @override
  State<ClassAssignmentScreen> createState() => _ClassAssignmentScreenState();
}

class _ClassAssignmentScreenState extends State<ClassAssignmentScreen> {
  final _searchController = TextEditingController();
  String _selectedClassId = '';
  List<Student> _availableStudents = [];
  List<Student> _assignedStudents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.targetClassId ?? '';
    // Load students after the widget is built to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    final studentsBox = Hive.box<Student>('students');
    final classSectionsBox = Hive.box<ClassSection>('class_sections');

    final allStudents = studentsBox.values.toList();
    final classSections = classSectionsBox.values.toList();

    // Set default class if none selected
    if (_selectedClassId.isEmpty && classSections.isNotEmpty) {
      _selectedClassId = classSections.first.id;
    }

    // Separate students by assignment status
    _availableStudents = allStudents.where((student) =>
      student.classSectionId == 'unassigned' ||
      student.classSectionId.isEmpty
    ).toList();

    _assignedStudents = allStudents.where((student) =>
      student.classSectionId == _selectedClassId &&
      student.classSectionId != 'unassigned' &&
      student.classSectionId.isNotEmpty
    ).toList();

    setState(() => _isLoading = false);
  }

  List<Student> _getFilteredStudents() {
    if (_searchController.text.isEmpty) {
      return _availableStudents;
    }

    final query = _searchController.text.toLowerCase().trim();
    return _availableStudents.where((student) {
      // Search by name
      final nameMatch = student.fullName.toLowerCase().contains(query);

      // Search by student ID
      final idMatch = (student.studentId?.toLowerCase().contains(query) ?? false) ||
                     student.id.toLowerCase().contains(query);

      // Search by grade
      final gradeMatch = student.grade?.toLowerCase().contains(query) ?? false;

      // Search by age (if query is a number)
      final ageMatch = int.tryParse(query) != null &&
                      student.age.toString().contains(query);

      return nameMatch || idMatch || gradeMatch || ageMatch;
    }).toList()
    ..sort((a, b) {
      // Sort by relevance: exact matches first, then partial matches
      final aName = a.fullName.toLowerCase();
      final bName = b.fullName.toLowerCase();
      final queryLower = query.toLowerCase();

      // Exact name match gets highest priority
      if (aName == queryLower && bName != queryLower) return -1;
      if (bName == queryLower && aName != queryLower) return 1;

      // Name starts with query gets second priority
      if (aName.startsWith(queryLower) && !bName.startsWith(queryLower)) return -1;
      if (bName.startsWith(queryLower) && !aName.startsWith(queryLower)) return 1;

      // Alphabetical sort as fallback
      return a.fullName.compareTo(b.fullName);
    });
  }

  Future<void> _assignStudentToClass(Student student) async {
    if (_selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first')),
      );
      return;
    }

    // Update student's class assignment
    student.classSectionId = _selectedClassId;
    await student.save();

    // Refresh the lists
    await _loadStudents();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${student.fullName} assigned to class successfully!')),
    );
  }

  Future<void> _unassignStudentFromClass(Student student) async {
    student.classSectionId = 'unassigned';
    await student.save();

    // Refresh the lists
    await _loadStudents();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${student.fullName} unassigned from class')),
    );
  }

  void _navigateToStudentRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegistrationScreen()),
    ).then((_) => _loadStudents()); // Refresh after registration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Assignment'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToStudentRegistration,
            tooltip: 'Register New Student',
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Selection and Search Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Class Selection Dropdown
                ValueListenableBuilder(
                  valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
                  builder: (context, Box<ClassSection> box, _) {
                    final classSections = box.values.toList();

                    if (classSections.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No classes available. Please create classes first.'),
                        ),
                      );
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassId.isEmpty ? (classSections.isNotEmpty ? classSections.first.id : null) : _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Select Class',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: classSections.map((classSection) {
                            return DropdownMenuItem<String>(
                              value: classSection.id,
                              child: Text('${classSection.name} (${_getClassStudentCount(classSection.id)})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedClassId = value);
                              _loadStudents();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a class';
                            }
                            return null;
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Quick Student Selection Dropdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Student Selection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder(
                          valueListenable: Hive.box<Student>('students').listenable(),
                          builder: (context, Box<Student> box, _) {
                            final availableStudents = box.values.where((student) =>
                              student.classSectionId == 'unassigned' ||
                              student.classSectionId.isEmpty
                            ).toList();

                            if (availableStudents.isEmpty) {
                              return const Text(
                                'No available students. Register new students first.',
                                style: TextStyle(color: Colors.grey),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Student to Assign',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_add),
                              ),
                              items: availableStudents.map((student) {
                                return DropdownMenuItem<String>(
                                  value: student.id,
                                  child: Text(
                                    '${student.fullName} (ID: ${student.studentId ?? student.id})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (studentId) {
                                if (studentId != null) {
                                  final student = availableStudents.firstWhere(
                                    (s) => s.id == studentId
                                  );
                                  _assignStudentToClass(student);
                                }
                              },
                              hint: const Text('Choose a student to assign'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Available Students',
                    hintText: 'Search by name, student ID, or grade',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 8),

                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip('Available', _availableStudents.length, Colors.blue),
                    _buildStatChip('Assigned', _assignedStudents.length, Colors.green),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId.isEmpty
                    ? const Center(child: Text('Please select a class to manage assignments'))
                    : SizedBox(
                        height: MediaQuery.of(context).size.height - 300, // Constrain height
                        child: Row(
                          children: [
                            // Available Students Panel
                            Expanded(
                              child: _buildStudentsPanel(
                                'Available Students',
                                _getFilteredStudents(),
                                Colors.blue,
                                (student) => _assignStudentToClass(student),
                                'Assign to Class',
                              ),
                            ),

                            // Divider
                            Container(
                              width: 1,
                              color: Colors.grey[300],
                            ),

                            // Assigned Students Panel
                            Expanded(
                              child: _buildStudentsPanel(
                                'Assigned Students',
                                _assignedStudents,
                                Colors.green,
                                (student) => _unassignStudentFromClass(student),
                                'Unassign from Class',
                                isAssignedPanel: true,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToStudentRegistration,
        backgroundColor: Colors.indigo,
        tooltip: 'Register New Student',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildStudentsPanel(
    String title,
    List<Student> students,
    Color themeColor,
    Function(Student) onAction,
    String actionLabel, {
    bool isAssignedPanel = false,
  }) {
    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.all(16.0),
          color: themeColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                isAssignedPanel ? Icons.check_circle : Icons.people,
                color: themeColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const Spacer(),
              Text(
                '${students.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAssignedPanel ? Icons.check_circle_outline : Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAssignedPanel
                            ? 'No students assigned to this class yet'
                            : 'No available students found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (!isAssignedPanel && _searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your search criteria',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: students.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: themeColor.withOpacity(0.2),
                          child: Text(
                            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'ID: ${student.studentId ?? student.id} • Grade: ${student.grade ?? "N/A"} • Age: ${student.age}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: SizedBox(
                          width: 100,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => onAction(student),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                              minimumSize: const Size(80, 36),
                            ),
                            child: Text(
                              isAssignedPanel ? 'Unassign' : 'Assign',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  int _getClassStudentCount(String classId) {
    final studentsBox = Hive.box<Student>('students');
    return studentsBox.values.where((student) => student.classSectionId == classId).length;
  }
}