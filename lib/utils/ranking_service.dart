import 'package:hive/hive.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:collection/collection.dart';

class StudentRank {
  final Student student;
  final double average;
  int rank;

  StudentRank({required this.student, required this.average, this.rank = 0});
}

class RankingService {
  static double _calculateOverallAverage(String studentId) {
    final scoresBox = Hive.box<Score>('scores');
    final studentScores = scoresBox.values.where((s) => s.studentId == studentId).toList();

    if (studentScores.isEmpty) {
      return 0.0;
    }

    final scoresBySubject = groupBy(studentScores, (Score s) => s.subjectId);
    if (scoresBySubject.isEmpty) {
      return 0.0;
    }

    double totalOfAverages = 0;
    scoresBySubject.forEach((subjectId, scores) {
      final totalMarks = scores.fold<double>(0, (sum, item) => sum + item.marks);
      final average = scores.isNotEmpty ? totalMarks / scores.length : 0.0;
      totalOfAverages += average;
    });

    return scoresBySubject.isNotEmpty ? totalOfAverages / scoresBySubject.length : 0.0;
  }

  static List<StudentRank> getRankedStudents(String classSectionId) {
    final studentsBox = Hive.box<Student>('students');
    final studentsInClass = studentsBox.values.where((s) => s.classSectionId == classSectionId).toList();

    if (studentsInClass.isEmpty) {
      return [];
    }

    List<StudentRank> studentRanks = studentsInClass.map((student) {
      final average = _calculateOverallAverage(student.id);
      return StudentRank(student: student, average: average);
    }).toList();

    studentRanks.sort((a, b) => b.average.compareTo(a.average));

    for (int i = 0; i < studentRanks.length; i++) {
      if (i > 0 && studentRanks[i].average == studentRanks[i - 1].average) {
        studentRanks[i].rank = studentRanks[i - 1].rank;
      } else {
        studentRanks[i].rank = i + 1;
      }
    }

    return studentRanks;
  }
}