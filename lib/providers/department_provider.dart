import 'package:flutter/cupertino.dart';

import '../api/api_service.dart';
import '../models/Department.dart';


class DepartmentProvider extends ChangeNotifier {
  List<Department> _departments = [];
  bool _isLoading = false;

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;

  DepartmentProvider() {
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      _isLoading = true;
      notifyListeners();

      _departments = await ApiService().fetchDepartments();
    } catch (e) {
      // Handle error appropriately
      debugPrint('Error fetching departments: $e');
      _departments = []; // Reset to empty list on error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}