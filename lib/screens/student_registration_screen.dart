import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'data_records_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _religionController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  DateTime? _selectedEnrollmentDate;
  String _selectedGender = 'Male';
  String _selectedGrade = 'Grade 1';
  String _selectedClassSection = '';

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _grades = [
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
    'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
    'Grade 11', 'Grade 12'
  ];

  @override
  void initState() {
    super.initState();
    _selectedEnrollmentDate = DateTime.now();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _bloodTypeController.dispose();
    _medicalConditionsController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 6)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _selectEnrollmentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEnrollmentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedEnrollmentDate) {
      setState(() {
        _selectedEnrollmentDate = picked;
      });
    }
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    try {
      final studentsBox = Hive.box<Student>('students');

      // Generate unique student ID if not provided
      final studentId = _studentIdController.text.isEmpty
          ? 'STU${DateTime.now().millisecondsSinceEpoch}'
          : _studentIdController.text;

      final newStudent = Student(
        id: studentId,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _selectedDateOfBirth!,
        gender: _selectedGender,
        classSectionId: _selectedClassSection.isEmpty ? 'unassigned' : _selectedClassSection,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim().isEmpty ? null : _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactPhoneController.text.trim().isEmpty ? null : _emergencyContactPhoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        enrollmentDate: _selectedEnrollmentDate,
        studentId: studentId,
        grade: _selectedGrade,
        bloodType: _bloodTypeController.text.trim().isEmpty ? null : _bloodTypeController.text.trim(),
        medicalConditions: _medicalConditionsController.text.trim().isEmpty ? null : _medicalConditionsController.text.trim(),
        nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
        religion: _religionController.text.trim().isEmpty ? null : _religionController.text.trim(),
      );

      await studentsBox.add(newStudent);

      // Automatically create a data record for the new student
      final recordsBox = Hive.box<DataRecord>('data_records');
      final studentRecord = DataRecord(
        id: 'student_${newStudent.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Student Registration: ${newStudent.fullName}',
        category: 'Student Records',
        content: '''
Student Registration Details:

Name: ${newStudent.fullName}
Student ID: ${newStudent.studentId ?? newStudent.id}
Grade: ${newStudent.grade ?? 'Not specified'}
Date of Birth: ${newStudent.dateOfBirth.toString().split(' ')[0] ?? 'Not specified'}
Gender: ${newStudent.gender}
Phone: ${newStudent.phoneNumber ?? 'Not provided'}
Address: ${newStudent.address ?? 'Not provided'}
Emergency Contact: ${newStudent.emergencyContactName ?? 'Not provided'}
Emergency Phone: ${newStudent.emergencyContactPhone ?? 'Not provided'}
Email: ${newStudent.email ?? 'Not provided'}
Registration Date: ${newStudent.enrollmentDate?.toString().split(' ')[0] ?? DateTime.now().toString().split(' ')[0]}

Additional Information:
Blood Type: ${newStudent.bloodType ?? 'Not specified'}
Medical Conditions: ${newStudent.medicalConditions ?? 'None specified'}
Nationality: ${newStudent.nationality ?? 'Not specified'}
Religion: ${newStudent.religion ?? 'Not specified'}
        ''',
        priority: 'Medium',
        status: 'Active',
        dateCreated: DateTime.now(),
        createdBy: 'System',
      );
      await recordsBox.add(studentRecord);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${newStudent.fullName}" registered successfully! Record created.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _clearForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _emergencyContactNameController.clear();
    _emergencyContactPhoneController.clear();
    _emailController.clear();
    _studentIdController.clear();
    _bloodTypeController.clear();
    _medicalConditionsController.clear();
    _nationalityController.clear();
    _religionController.clear();

    setState(() {
      _selectedDateOfBirth = null;
      _selectedEnrollmentDate = DateTime.now();
      _selectedGender = 'Male';
      _selectedGrade = 'Grade 1';
      _selectedClassSection = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Student'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: () {
              // TODO: Navigate to photo upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo upload coming soon!')),
              );
            },
            tooltip: 'Add Student Photo',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataRecordsScreen(),
                ),
              );
            },
            tooltip: 'View Data Records',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildProgressStep('Basic Info', true),
                      _buildProgressConnector(true),
                      _buildProgressStep('Contact', false),
                      _buildProgressConnector(false),
                      _buildProgressStep('Academic', false),
                      _buildProgressConnector(false),
                      _buildProgressStep('Medical', false),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Basic Information Section
                _buildSectionCard(
                  title: '👤 Basic Information',
                  subtitle: 'Student personal details',
                  icon: Icons.person,
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter student full name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _studentIdController,
                      label: 'Student ID',
                      icon: Icons.badge,
                      hint: 'Leave empty to auto-generate',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerField(
                            label: 'Date of Birth *',
                            selectedDate: _selectedDateOfBirth,
                            onTap: () => _selectDateOfBirth(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Gender *',
                            value: _selectedGender,
                            items: _genders,
                            onChanged: (value) => setState(() => _selectedGender = value!),
                            icon: Icons.people,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Contact Information Section
                _buildSectionCard(
                  title: '📞 Contact Information',
                  subtitle: 'Phone, email, and address',
                  icon: Icons.phone,
                  children: [
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.home,
                      maxLines: 3,
                    ),
                  ],
                ),

                // Academic Information Section
                _buildSectionCard(
                  title: '🎓 Academic Information',
                  subtitle: 'Grade and enrollment details',
                  icon: Icons.school,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Grade *',
                            value: _selectedGrade,
                            items: _grades,
                            onChanged: (value) => setState(() => _selectedGrade = value!),
                            icon: Icons.school,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePickerField(
                            label: 'Enrollment Date',
                            selectedDate: _selectedEnrollmentDate,
                            onTap: () => _selectEnrollmentDate(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Emergency Contact Section
                _buildSectionCard(
                  title: '🚨 Emergency Contact',
                  subtitle: 'Important contact information',
                  icon: Icons.contact_emergency,
                  children: [
                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      icon: Icons.contact_emergency,
                    ),
                    _buildTextField(
                      controller: _emergencyContactPhoneController,
                      label: 'Emergency Contact Phone',
                      icon: Icons.phone_callback,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                // Medical Information Section
                _buildSectionCard(
                  title: '🏥 Medical Information',
                  subtitle: 'Health and medical details',
                  icon: Icons.medical_information,
                  children: [
                    _buildTextField(
                      controller: _bloodTypeController,
                      label: 'Blood Type',
                      icon: Icons.bloodtype,
                      hint: 'e.g., A+, B-, O+',
                    ),
                    _buildTextField(
                      controller: _medicalConditionsController,
                      label: 'Medical Conditions',
                      icon: Icons.medical_information,
                      hint: 'Any allergies or medical conditions',
                      maxLines: 2,
                    ),
                  ],
                ),

                // Additional Information Section
                _buildSectionCard(
                  title: '🌍 Additional Information',
                  subtitle: 'Nationality and religion',
                  icon: Icons.flag,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _nationalityController,
                            label: 'Nationality',
                            icon: Icons.flag,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _religionController,
                            label: 'Religion',
                            icon: Icons.church,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _registerStudent,
                              icon: const Icon(Icons.save),
                              label: const Text('Register Student'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearForm,
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Form'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '* Required fields',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          child: Text(
            selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(selectedDate)
                : 'Select date',
            style: TextStyle(
              color: selectedDate != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.indigo : Colors.grey[300],
            ),
            child: Icon(
              Icons.check,
              color: isActive ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.indigo : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? Colors.indigo : Colors.grey[300],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}