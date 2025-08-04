// =============================================================
// FILE: lib/screens/teacher_assistant/attendance_tracker_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_school_assistant/models.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  final ClassSection classSection;
  final List<Student> students;

  const AttendanceTrackerScreen({
    super.key,
    required this.classSection,
    required this.students,
  });

  @override
  State<AttendanceTrackerScreen> createState() => _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  late DateTime _selectedDate;
  // Map to hold the attendance status for each student for the selected day
  late Map<String, String> _attendanceStatus;
  final Box<AttendanceRecord> _attendanceBox = Hive.box<AttendanceRecord>('attendance_records');

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _attendanceStatus = {};
    _loadAttendanceForSelectedDate();
  }

  // Load existing attendance data for the current date or set defaults
  void _loadAttendanceForSelectedDate() {
    setState(() {
      _attendanceStatus.clear();
      for (var student in widget.students) {
        final record = _findAttendanceRecord(student.id, _selectedDate);
        // Default to 'Present' if no record exists for that day
        _attendanceStatus[student.id] = record?.status ?? 'Present';
      }
    });
  }

  // Helper to find a specific attendance record
  AttendanceRecord? _findAttendanceRecord(String studentId, DateTime date) {
    // A more efficient query might be needed for very large datasets,
    // but this is fine for a single class.
    for (var record in _attendanceBox.values) {
      if (record.studentId == studentId &&
          DateUtils.isSameDay(record.date, date)) {
        return record;
      }
    }
    return null;
  }

  void _updateAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  void _saveAttendance() {
    _attendanceStatus.forEach((studentId, status) {
      final existingRecord = _findAttendanceRecord(studentId, _selectedDate);

      if (existingRecord != null) {
        // Update existing record if status changed
        if (existingRecord.status != status) {
          existingRecord.status = status;
          existingRecord.save();
        }
      } else {
        // Create a new record
        final newRecord = AttendanceRecord(
          studentId: studentId,
          date: _selectedDate,
          status: status,
        );
        _attendanceBox.add(newRecord);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadAttendanceForSelectedDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Date Selector ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                  tooltip: 'Select Date',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // --- Student List ---
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final status = _attendanceStatus[student.id] ?? 'Present';

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(student.fullName.isNotEmpty ? student.fullName[0] : '?'),
                  ),
                  title: Text(student.fullName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: 'Present',
                        groupValue: status,
                        onChanged: (value) => _updateAttendance(student.id, value!),
                      ),
                      const Text('P'),
                      Radio<String>(
                        value: 'Absent',
                        groupValue: status,
                        onChanged: (value) => _updateAttendance(student.id, value!),
                      ),
                      const Text('A'),
                      Radio<String>(
                        value: 'Late',
                        groupValue: status,
                        onChanged: (value) => _updateAttendance(student.id, value!),
                      ),
                      const Text('L'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
