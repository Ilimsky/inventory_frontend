import 'package:flutter/material.dart';
import '../api/ApiService.dart';
import '../models/Binding.dart';

class BindingProvider extends ChangeNotifier {
  List<Binding> _bindings = [];
  bool _isLoading = false;

  List<Binding> get bindings => _bindings;
  bool get isLoading => _isLoading;

  Future<void> fetchBindings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bindings = await ApiService().fetchBindings();
    } catch (e) {
      print('[ERROR] Failed to fetch bindings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
