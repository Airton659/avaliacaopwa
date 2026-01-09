import 'employee_snapshot.dart';
import 'evaluation_type.dart';

class Evaluation {
  final String id; // formato: {year}_{employeeId}_{type}
  final int year;
  final EvaluationType type;
  final Map<String, int> answers; // q1: 5, q2: 4, etc.
  final String? obs;
  final EmployeeSnapshot employeeSnapshot;
  final DateTime createdAt;

  Evaluation({
    required this.id,
    required this.year,
    required this.type,
    required this.answers,
    this.obs,
    required this.employeeSnapshot,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static String generateId(int year, String employeeId, EvaluationType type) {
    return '${year}_${employeeId}_${type.code}';
  }

  double get average {
    if (answers.isEmpty) return 0;
    final sum = answers.values.reduce((a, b) => a + b);
    return sum / answers.length;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'year': year,
      'type': type.code,
      'answers': answers,
      'obs': obs,
      'employeeSnapshot': employeeSnapshot.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Evaluation.fromFirestore(Map<String, dynamic> data) {
    return Evaluation(
      id: data['id'] as String,
      year: data['year'] as int,
      type: EvaluationType.fromCode(data['type'] as String),
      answers: Map<String, int>.from(data['answers'] as Map),
      obs: data['obs'] as String?,
      employeeSnapshot: EmployeeSnapshot.fromMap(
        data['employeeSnapshot'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}
