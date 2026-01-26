import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String? signatureUrl;
  final Map<String, dynamic>? pdfData; // Stores persistent PDF headers (Tipo, Ocorrencia, etc.)

  // Immutable Commission President Data (Snapshot on Conclusion)
  final String? commissionPresidentName;
  final String? commissionPresidentSignatureUrl; // Signature Image
  final String? commissionPresidentPhotoUrl; // Face Photo (for QR)
  final Map<String, dynamic>? commissionPresidentMetadata; // Location etc.

  Evaluation({
    required this.id,
    required this.year,
    required this.type,
    required this.answers,
    this.obs,
    required this.employeeSnapshot,
    DateTime? createdAt,
    this.signatureUrl,
    this.pdfData,
    this.commissionPresidentName,
    this.commissionPresidentSignatureUrl,
    this.commissionPresidentPhotoUrl,
    this.commissionPresidentMetadata,
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
      'signatureUrl': signatureUrl,
      'pdfData': pdfData,
      'commissionPresidentName': commissionPresidentName,
      'commissionPresidentSignatureUrl': commissionPresidentSignatureUrl,
      'commissionPresidentPhotoUrl': commissionPresidentPhotoUrl,
      'commissionPresidentMetadata': commissionPresidentMetadata,
    };
  }

  factory Evaluation.fromFirestore(Map<String, dynamic> data) {
    // Handle Year (int or String, 'year' or 'ano' or 'ciclo')
    int parsedYear = DateTime.now().year;
    if (data['year'] != null) {
      parsedYear = int.tryParse(data['year'].toString()) ?? parsedYear;
    } else if (data['ano'] != null) {
      parsedYear = int.tryParse(data['ano'].toString()) ?? parsedYear;
    } else if (data['ciclo'] != null) {
      parsedYear = int.tryParse(data['ciclo'].toString()) ?? parsedYear;
    }

    // Handle CreatedAt (Timestamp or String or null)
    DateTime parsedCreatedAt = DateTime.now();
    if (data['createdAt'] != null) {
       if (data['createdAt'] is Function) { 
          // Firestore sometimes returns a FieldValue.serverTimestamp() placeholder locally before sync
          // Ignore
       } else if (data.toString().contains('Timestamp')) { // Runtime check if it's cloud_firestore Value
          // Dynamic invocation to avoid direct dependency if type not imported
          // But we have Timestamp imported in other files.
          // Better: Check try/catch
          try {
             parsedCreatedAt = data['createdAt'].toDate();
          } catch (_) {
             parsedCreatedAt = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
          }
       } else {
          parsedCreatedAt = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
       }
    }

    // Handle ID (might be missing in data, usually doc.id passed separately but here we accept data)
    final id = data['id']?.toString() ?? '${parsedYear}_${data['employeeId'] ?? 'unknown'}_${data['tipo'] ?? 'UNKNOWN'}';

    return Evaluation(
      id: id,
      year: parsedYear,
      type: EvaluationType.fromCode(data['tipo'] as String? ?? 'AUTO_OPERACIONAL'),
      answers: Map<String, int>.from(data['respostas'] as Map? ?? data['answers'] as Map? ?? {}),
      obs: data['obs'] as String? ?? data['observacoes'] as String?,
      employeeSnapshot: EmployeeSnapshot.fromMap(
        data['employeeSnapshot'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: parsedCreatedAt,
      signatureUrl: data['signatureUrl'] as String?,
      pdfData: data['pdfData'] as Map<String, dynamic>?,
      commissionPresidentName: data['commissionPresidentName'] as String?,
      commissionPresidentSignatureUrl: data['commissionPresidentSignatureUrl'] as String?,
      commissionPresidentPhotoUrl: data['commissionPresidentPhotoUrl'] as String?,
      commissionPresidentMetadata: data['commissionPresidentMetadata'] as Map<String, dynamic>?,
    );
  }
}
