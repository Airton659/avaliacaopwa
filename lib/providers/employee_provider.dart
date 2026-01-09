import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../services/firebase_service.dart';

class EmployeeProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Employee> _employees = [];
  bool _isLoading = false;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;

  Future<void> loadEmployees() async {
    _isLoading = true;
    notifyListeners();

    try {
      _employees = await _firebaseService.getEmployees();
    } catch (e) {
      debugPrint('Erro ao carregar funcionários: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> promoteToManager(String employeeId) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) return;

    final updatedEmployee = _employees[index].copyWith(
      isManager: true,
      managerId: null,
    );

    await _firebaseService.updateEmployee(updatedEmployee);
    _employees[index] = updatedEmployee;
    notifyListeners();
  }

  Future<void> demoteManager(String employeeId) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) return;

    final updatedEmployee = _employees[index].copyWith(
      isManager: false,
    );

    await _firebaseService.updateEmployee(updatedEmployee);
    _employees[index] = updatedEmployee;
    notifyListeners();
  }

  Future<void> assignEmployeeToManager(
    String employeeId,
    String managerId,
  ) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) return;

    final updatedEmployee = _employees[index].copyWith(
      managerId: managerId,
    );

    await _firebaseService.updateEmployee(updatedEmployee);
    _employees[index] = updatedEmployee;
    notifyListeners();
  }

  Future<void> removeEmployeeFromManager(String employeeId) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) return;

    final updatedEmployee = _employees[index].copyWith(
      managerId: null,
    );

    await _firebaseService.updateEmployee(updatedEmployee);
    _employees[index] = updatedEmployee;
    notifyListeners();
  }

  Future<void> importFromGoogleSheets(List<Employee> newEmployees) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mantém os dados de isManager e managerId existentes
      final Map<String, Employee> existingMap = {
        for (var e in _employees) e.id: e,
      };

      final updatedEmployees = newEmployees.map((newEmp) {
        final existing = existingMap[newEmp.id];
        if (existing != null) {
          return newEmp.copyWith(
            isManager: existing.isManager,
            managerId: existing.managerId,
          );
        }
        return newEmp;
      }).toList();

      await _firebaseService.batchUpdateEmployees(updatedEmployees);
      _employees = updatedEmployees;
    } catch (e) {
      debugPrint('Erro ao importar funcionários: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
