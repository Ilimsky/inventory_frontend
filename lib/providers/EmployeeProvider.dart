import 'package:flutter/cupertino.dart';

import '../api/ApiService.dart';
import '../models/Employee.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = false;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;

  EmployeeProvider() {
    fetchEmployees();
  }

  void fetchEmployees() async {
    _isLoading = true;
    notifyListeners();

    _employees = await ApiService().fetchEmployees();
    _isLoading = false;
    notifyListeners();
  }
}