import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';
import '../models/question.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Employee operations
  Future<List<Employee>> getEmployees() async {
    final snapshot = await _firestore.collection('funcionarios').get();
    return snapshot.docs
        .map((doc) => Employee.fromFirestore(doc.data()))
        .toList();
  }

  Future<List<Employee>> getActiveEmployees() async {
    final snapshot = await _firestore
        .collection('funcionarios')
        .where('situacao', isEqualTo: 'Ativo')
        .get();
    return snapshot.docs
        .map((doc) => Employee.fromFirestore(doc.data()))
        .toList();
  }

  Future<Employee?> getEmployeeById(String id) async {
    final doc = await _firestore.collection('funcionarios').doc(id).get();
    if (!doc.exists) return null;
    return Employee.fromFirestore(doc.data()!);
  }

  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .collection('funcionarios')
        .doc(employee.id)
        .set(employee.toFirestore());
  }

  Future<void> batchUpdateEmployees(List<Employee> employees) async {
    final batch = _firestore.batch();
    for (final employee in employees) {
      final docRef = _firestore.collection('funcionarios').doc(employee.id);
      batch.set(docRef, employee.toFirestore());
    }
    await batch.commit();
  }

  Future<List<Employee>> getManagerTeam(String managerId) async {
    final snapshot = await _firestore
        .collection('funcionarios')
        .where('managerId', isEqualTo: managerId)
        .where('situacao', isEqualTo: 'Ativo')
        .get();
    return snapshot.docs
        .map((doc) => Employee.fromFirestore(doc.data()))
        .toList();
  }

  // Evaluation operations
  Future<void> saveEvaluation(Evaluation evaluation) async {
    await _firestore
        .collection('evaluations')
        .doc(evaluation.id)
        .set(evaluation.toFirestore());
  }

  Future<Evaluation?> getEvaluation(String evaluationId) async {
    final doc =
        await _firestore.collection('evaluations').doc(evaluationId).get();
    if (!doc.exists) return null;
    return Evaluation.fromFirestore(doc.data()!);
  }

  Future<List<Evaluation>> getEmployeeEvaluations(
    String employeeId,
    int year,
  ) async {
    final snapshot = await _firestore
        .collection('evaluations')
        .where('id', isGreaterThanOrEqualTo: '${year}_${employeeId}_')
        .where('id', isLessThan: '${year}_${employeeId}_Z')
        .get();

    return snapshot.docs
        .map((doc) => Evaluation.fromFirestore(doc.data()))
        .toList();
  }

  Future<List<Evaluation>> getEvaluationsByYear(int year) async {
    final snapshot = await _firestore
        .collection('evaluations')
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => Evaluation.fromFirestore(doc.data()))
        .toList();
  }

  // Question operations
  Future<List<Question>> getQuestions() async {
    final snapshot = await _firestore
        .collection('questions')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.data()))
        .toList();
  }

  Stream<List<Employee>> employeesStream() {
    return _firestore.collection('funcionarios').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Employee.fromFirestore(doc.data()))
              .toList(),
        );
  }
}
