// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 0;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      fullName: fields[1] as String,
      photoPath: fields[2] as String?,
      dateOfBirth: fields[3] as DateTime,
      gender: fields[4] as String,
      classSectionId: fields[5] as String,
      phoneNumber: fields[6] as String?,
      address: fields[7] as String?,
      emergencyContactName: fields[8] as String?,
      emergencyContactPhone: fields[9] as String?,
      email: fields[10] as String?,
      enrollmentDate: fields[11] as DateTime?,
      studentId: fields[12] as String?,
      grade: fields[13] as String?,
      bloodType: fields[14] as String?,
      medicalConditions: fields[15] as String?,
      nationality: fields[16] as String?,
      religion: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.classSectionId)
      ..writeByte(6)
      ..write(obj.phoneNumber)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.emergencyContactName)
      ..writeByte(9)
      ..write(obj.emergencyContactPhone)
      ..writeByte(10)
      ..write(obj.email)
      ..writeByte(11)
      ..write(obj.enrollmentDate)
      ..writeByte(12)
      ..write(obj.studentId)
      ..writeByte(13)
      ..write(obj.grade)
      ..writeByte(14)
      ..write(obj.bloodType)
      ..writeByte(15)
      ..write(obj.medicalConditions)
      ..writeByte(16)
      ..write(obj.nationality)
      ..writeByte(17)
      ..write(obj.religion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TeacherAdapter extends TypeAdapter<Teacher> {
  @override
  final int typeId = 1;

  @override
  Teacher read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Teacher(
      id: fields[0] as String,
      fullName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Teacher obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 2;

  @override
  Subject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subject(
      id: fields[0] as String,
      name: fields[1] as String,
      teacherId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.teacherId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClassSectionAdapter extends TypeAdapter<ClassSection> {
  @override
  final int typeId = 3;

  @override
  ClassSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSection(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClassSection obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScoreAdapter extends TypeAdapter<Score> {
  @override
  final int typeId = 4;

  @override
  Score read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Score(
      studentId: fields[0] as String,
      subjectId: fields[1] as String,
      assessmentType: fields[2] as String,
      marks: fields[3] as double,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Score obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.assessmentType)
      ..writeByte(3)
      ..write(obj.marks)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 5;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      studentId: fields[0] as String,
      date: fields[1] as DateTime,
      status: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeTableEntryAdapter extends TypeAdapter<TimeTableEntry> {
  @override
  final int typeId = 6;

  @override
  TimeTableEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeTableEntry(
      dayOfWeek: fields[0] as String,
      period: fields[1] as String,
      subjectId: fields[2] as String,
      classSectionId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TimeTableEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.period)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.classSectionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeTableEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PeriodAdapter extends TypeAdapter<Period> {
  @override
  final int typeId = 7;

  @override
  Period read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Period(
      id: fields[0] as String,
      name: fields[1] as String,
      time: fields[2] as String,
      isBreak: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Period obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.isBreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 8;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as int,
      type: fields[3] as String,
      condition: fields[4] as String,
      description: fields[5] as String,
      dateAdded: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.condition)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DataRecordAdapter extends TypeAdapter<DataRecord> {
  @override
  final int typeId = 9;

  @override
  DataRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataRecord(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      content: fields[3] as String,
      attachmentPath: fields[4] as String?,
      priority: fields[5] as String,
      status: fields[6] as String,
      dateCreated: fields[7] as DateTime,
      lastModified: fields[8] as DateTime?,
      createdBy: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DataRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.attachmentPath)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.dateCreated)
      ..writeByte(8)
      ..write(obj.lastModified)
      ..writeByte(9)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssessmentAdapter extends TypeAdapter<Assessment> {
  @override
  final int typeId = 10;

  @override
  Assessment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Assessment(
      id: fields[0] as String,
      name: fields[1] as String,
      subjectId: fields[2] as String,
      classSectionId: fields[3] as String,
      semesterId: fields[4] as String,
      weight: fields[5] as double,
      maxMarks: fields[6] as double,
      dueDate: fields[7] as DateTime,
      description: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Assessment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.classSectionId)
      ..writeByte(4)
      ..write(obj.semesterId)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.maxMarks)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SemesterAdapter extends TypeAdapter<Semester> {
  @override
  final int typeId = 11;

  @override
  Semester read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Semester(
      id: fields[0] as String,
      name: fields[1] as String,
      academicYear: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Semester obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.academicYear)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssessmentScoreAdapter extends TypeAdapter<AssessmentScore> {
  @override
  final int typeId = 12;

  @override
  AssessmentScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssessmentScore(
      id: fields[0] as String,
      studentId: fields[1] as String,
      assessmentId: fields[2] as String,
      marksObtained: fields[3] as double,
      dateRecorded: fields[4] as DateTime,
      recordedBy: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AssessmentScore obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.assessmentId)
      ..writeByte(3)
      ..write(obj.marksObtained)
      ..writeByte(4)
      ..write(obj.dateRecorded)
      ..writeByte(5)
      ..write(obj.recordedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
