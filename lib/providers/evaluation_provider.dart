import 'package:flutter/foundation.dart';
import '../models/evaluation.dart';
import '../services/firebase_service.dart';

class EvaluationProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Evaluation> _evaluations = [];
  bool _isLoading = false;

  List<Evaluation> get evaluations => _evaluations;
  bool get isLoading => _isLoading;

  Future<void> saveEvaluation(Evaluation evaluation) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.saveEvaluation(evaluation);
      _evaluations.add(evaluation);
    } catch (e) {
      debugPrint('Erro ao salvar avaliação: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Evaluation?> getEvaluation(String evaluationId) async {
    try {
      return await _firebaseService.getEvaluation(evaluationId);
    } catch (e) {
      debugPrint('Erro ao buscar avaliação: $e');
      return null;
    }
  }

  Future<void> loadEvaluationsByYear(int year) async {
    _isLoading = true;
    notifyListeners();

    try {
      _evaluations = await _firebaseService.getEvaluationsByYear(year);
    } catch (e) {
      debugPrint('Erro ao carregar avaliações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Evaluation>> getEmployeeEvaluations(
    String employeeId,
    int year,
  ) async {
    try {
      return await _firebaseService.getEmployeeEvaluations(employeeId, year);
    } catch (e) {
      debugPrint('Erro ao carregar avaliações do funcionário: $e');
      return [];
    }
  }
}
