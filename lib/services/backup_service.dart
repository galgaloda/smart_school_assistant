import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';

class BackupService {
  static const String backupFileName = 'smart_school_backup';

  /// Export all data to JSON format
  static Future<String> exportData() async {
    try {
      final data = {
        'metadata': {
          'version': '1.0.0',
          'exportDate': DateTime.now().toIso8601String(),
          'appName': 'Smart School Assistant',
        },
        'data': {
          'class_sections': _exportBox<ClassSection>('class_sections'),
          'students': _exportBox<Student>('students'),
          'teachers': _exportBox<Teacher>('teachers'),
          'subjects': _exportBox<Subject>('subjects'),
          'periods': _exportBox<Period>('periods'),
          'timetable_entries': _exportBox<TimeTableEntry>('timetable_entries'),
          'attendance_records': _exportBox<AttendanceRecord>('attendance_records'),
          'scores': _exportBox<Score>('scores'),
          'inventory_items': _exportBox<InventoryItem>('inventory_items'),
          'data_records': _exportBox<DataRecord>('data_records'),
          'semesters': _exportBox<Semester>('semesters'),
          'assessments': _exportBox<Assessment>('assessments'),
          'assessment_scores': _exportBox<AssessmentScore>('assessment_scores'),
        }
      };

      final jsonString = jsonEncode(data);
      return jsonString;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export a specific Hive box to JSON
  static List<Map<String, dynamic>> _exportBox<T>(String boxName) {
    try {
      final box = Hive.box<T>(boxName);
      final items = box.values.toList();

      // Convert Hive objects to JSON
      final result = <Map<String, dynamic>>[];
      for (final item in items) {
        if (item is ClassSection) {
          result.add({
            'id': item.id,
            'name': item.name,
          });
        } else if (item is Student) {
          result.add({
            'id': item.id,
            'fullName': item.fullName,
            'photoPath': item.photoPath,
            'dateOfBirth': item.dateOfBirth.toIso8601String(),
            'gender': item.gender,
            'classSectionId': item.classSectionId,
          });
        } else if (item is Teacher) {
          result.add({
            'id': item.id,
            'fullName': item.fullName,
          });
        } else if (item is Subject) {
          result.add({
            'id': item.id,
            'name': item.name,
            'teacherId': item.teacherId,
          });
        } else if (item is Period) {
          result.add({
            'id': item.id,
            'name': item.name,
            'time': item.time,
            'isBreak': item.isBreak,
          });
        } else if (item is TimeTableEntry) {
          result.add({
            'dayOfWeek': item.dayOfWeek,
            'period': item.period,
            'subjectId': item.subjectId,
            'classSectionId': item.classSectionId,
          });
        } else if (item is AttendanceRecord) {
          result.add({
            'studentId': item.studentId,
            'date': item.date.toIso8601String(),
            'status': item.status,
          });
        } else if (item is Score) {
          result.add({
            'studentId': item.studentId,
            'subjectId': item.subjectId,
            'assessmentType': item.assessmentType,
            'marks': item.marks,
            'date': item.date.toIso8601String(),
          });
        } else if (item is InventoryItem) {
          result.add({
            'id': item.id,
            'name': item.name,
            'quantity': item.quantity,
            'type': item.type,
            'condition': item.condition,
            'description': item.description,
            'dateAdded': item.dateAdded.toIso8601String(),
          });
        } else if (item is DataRecord) {
          result.add({
            'id': item.id,
            'title': item.title,
            'category': item.category,
            'content': item.content,
            'attachmentPath': item.attachmentPath,
            'priority': item.priority,
            'status': item.status,
            'dateCreated': item.dateCreated.toIso8601String(),
            'lastModified': item.lastModified?.toIso8601String(),
            'createdBy': item.createdBy,
          });
        } else if (item is Semester) {
          result.add({
            'id': item.id,
            'name': item.name,
            'academicYear': item.academicYear,
            'startDate': item.startDate.toIso8601String(),
            'endDate': item.endDate.toIso8601String(),
            'isActive': item.isActive,
          });
        } else if (item is Assessment) {
          result.add({
            'id': item.id,
            'name': item.name,
            'subjectId': item.subjectId,
            'classSectionId': item.classSectionId,
            'semesterId': item.semesterId,
            'weight': item.weight,
            'maxMarks': item.maxMarks,
            'dueDate': item.dueDate.toIso8601String(),
            'description': item.description,
          });
        } else if (item is AssessmentScore) {
          result.add({
            'id': item.id,
            'studentId': item.studentId,
            'assessmentId': item.assessmentId,
            'marksObtained': item.marksObtained,
            'dateRecorded': item.dateRecorded.toIso8601String(),
            'recordedBy': item.recordedBy,
          });
        }
      }
      return result;
    } catch (e) {
      print('Error exporting box $boxName: $e');
      return [];
    }
  }

  /// Save backup to file and share
  static Future<void> saveBackupToFile() async {
    try {
      final jsonData = await exportData();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = '${backupFileName}_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Smart School Assistant Backup - $timestamp',
      );
    } catch (e) {
      throw Exception('Failed to save backup: $e');
    }
  }

  /// Import data from JSON backup
  static Future<Map<String, int>> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);

      if (!data.containsKey('data')) {
        throw Exception('Invalid backup file format');
      }

      final importResults = <String, int>{};
      final dataSection = data['data'] as Map<String, dynamic>;

      // Import in order to maintain relationships
      importResults.addAll(await _importBox<ClassSection>('class_sections', dataSection));
      importResults.addAll(await _importBox<Teacher>('teachers', dataSection));
      importResults.addAll(await _importBox<Subject>('subjects', dataSection));
      importResults.addAll(await _importBox<Student>('students', dataSection));
      importResults.addAll(await _importBox<Period>('periods', dataSection));
      importResults.addAll(await _importBox<Semester>('semesters', dataSection));
      importResults.addAll(await _importBox<Assessment>('assessments', dataSection));
      importResults.addAll(await _importBox<TimeTableEntry>('timetable_entries', dataSection));
      importResults.addAll(await _importBox<AttendanceRecord>('attendance_records', dataSection));
      importResults.addAll(await _importBox<Score>('scores', dataSection));
      importResults.addAll(await _importBox<AssessmentScore>('assessment_scores', dataSection));
      importResults.addAll(await _importBox<InventoryItem>('inventory_items', dataSection));
      importResults.addAll(await _importBox<DataRecord>('data_records', dataSection));

      return importResults;
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  /// Import a specific box from JSON data
  static Future<Map<String, int>> _importBox<T>(String boxName, Map<String, dynamic> dataSection) async {
    try {
      if (!dataSection.containsKey(boxName)) {
        return {boxName: 0};
      }

      final box = Hive.box<T>(boxName);
      final items = dataSection[boxName] as List<dynamic>;
      int importedCount = 0;

      for (final itemData in items) {
        try {
          final item = _createObjectFromJson<T>(boxName, itemData as Map<String, dynamic>);
          if (item != null) {
            await box.add(item);
            importedCount++;
          }
        } catch (e) {
          print('Error importing item from $boxName: $e');
        }
      }

      return {boxName: importedCount};
    } catch (e) {
      print('Error importing box $boxName: $e');
      return {boxName: 0};
    }
  }

  /// Create object from JSON data
  static T? _createObjectFromJson<T>(String boxName, Map<String, dynamic> data) {
    try {
      switch (boxName) {
        case 'class_sections':
          return ClassSection(
            id: data['id'],
            name: data['name'],
          ) as T;
        case 'students':
          return Student(
            id: data['id'],
            fullName: data['fullName'],
            photoPath: data['photoPath'],
            dateOfBirth: DateTime.parse(data['dateOfBirth']),
            gender: data['gender'] ?? 'Not Specified',
            classSectionId: data['classSectionId'],
          ) as T;
        case 'teachers':
          return Teacher(
            id: data['id'],
            fullName: data['fullName'],
          ) as T;
        case 'subjects':
          return Subject(
            id: data['id'],
            name: data['name'],
            teacherId: data['teacherId'],
          ) as T;
        case 'periods':
          return Period(
            id: data['id'],
            name: data['name'],
            time: data['time'],
            isBreak: data['isBreak'] ?? false,
          ) as T;
        case 'semesters':
          return Semester(
            id: data['id'],
            name: data['name'],
            academicYear: data['academicYear'],
            startDate: DateTime.parse(data['startDate']),
            endDate: DateTime.parse(data['endDate']),
            isActive: data['isActive'] ?? false,
          ) as T;
        case 'assessments':
          return Assessment(
            id: data['id'],
            name: data['name'],
            subjectId: data['subjectId'],
            classSectionId: data['classSectionId'],
            semesterId: data['semesterId'],
            weight: (data['weight'] as num).toDouble(),
            maxMarks: (data['maxMarks'] as num).toDouble(),
            dueDate: DateTime.parse(data['dueDate']),
            description: data['description'],
          ) as T;
        case 'timetable_entries':
          return TimeTableEntry(
            dayOfWeek: data['dayOfWeek'],
            period: data['period'],
            subjectId: data['subjectId'],
            classSectionId: data['classSectionId'],
          ) as T;
        case 'attendance_records':
          return AttendanceRecord(
            studentId: data['studentId'],
            date: DateTime.parse(data['date']),
            status: data['status'],
          ) as T;
        case 'scores':
          return Score(
            studentId: data['studentId'],
            subjectId: data['subjectId'],
            assessmentType: data['assessmentType'],
            marks: (data['marks'] as num).toDouble(),
            date: DateTime.parse(data['date']),
          ) as T;
        case 'assessment_scores':
          return AssessmentScore(
            id: data['id'],
            studentId: data['studentId'],
            assessmentId: data['assessmentId'],
            marksObtained: (data['marksObtained'] as num).toDouble(),
            dateRecorded: DateTime.parse(data['dateRecorded']),
            recordedBy: data['recordedBy'],
          ) as T;
        case 'inventory_items':
          return InventoryItem(
            id: data['id'],
            name: data['name'],
            quantity: data['quantity'],
            type: data['type'],
            condition: data['condition'],
            description: data['description'],
            dateAdded: DateTime.parse(data['dateAdded']),
          ) as T;
        case 'data_records':
          return DataRecord(
            id: data['id'],
            title: data['title'],
            category: data['category'],
            content: data['content'],
            attachmentPath: data['attachmentPath'],
            priority: data['priority'],
            status: data['status'],
            dateCreated: DateTime.parse(data['dateCreated']),
            lastModified: data['lastModified'] != null ? DateTime.parse(data['lastModified']) : null,
            createdBy: data['createdBy'],
          ) as T;
        default:
          return null;
      }
    } catch (e) {
      print('Error creating object for $boxName: $e');
      return null;
    }
  }

  /// Pick and import backup file
  static Future<Map<String, int>?> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();
        return await importData(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to import from file: $e');
    }
  }

  /// Clear all data (for restore operations)
  static Future<void> clearAllData() async {
    try {
      await Hive.box<ClassSection>('class_sections').clear();
      await Hive.box<Student>('students').clear();
      await Hive.box<Teacher>('teachers').clear();
      await Hive.box<Subject>('subjects').clear();
      await Hive.box<Period>('periods').clear();
      await Hive.box<TimeTableEntry>('timetable_entries').clear();
      await Hive.box<AttendanceRecord>('attendance_records').clear();
      await Hive.box<Score>('scores').clear();
      await Hive.box<InventoryItem>('inventory_items').clear();
      await Hive.box<DataRecord>('data_records').clear();
      await Hive.box<Semester>('semesters').clear();
      await Hive.box<Assessment>('assessments').clear();
      await Hive.box<AssessmentScore>('assessment_scores').clear();
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  /// Get backup file size estimate
  static Future<String> getDataSizeEstimate() async {
    try {
      final jsonData = await exportData();
      final bytes = utf8.encode(jsonData).length;

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}