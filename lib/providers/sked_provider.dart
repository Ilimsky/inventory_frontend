import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/SkedHistory.dart';
import '../web_socket_service/sked_web_socket_service.dart';
import '../api/api_service.dart';
import '../models/Department.dart';
import '../models/Sked.dart';
import 'department_provider.dart';

class SkedProvider extends ChangeNotifier {
  final SkedWebSocketService _wsService;

  SkedWebSocketService get wsService => _wsService;

  late final DepartmentProvider departmentProvider;

  SkedProvider({required this.departmentProvider})
      : _wsService = SkedWebSocketService() {
    _wsService.connect();
  }

  List<Sked> _skeds = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentDepartmentId;

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  int _pageSize = 20;
  String? _currentSort;

  List<Sked> get skeds => _skeds;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int? get currentDepartmentId => _currentDepartmentId;

  int get currentPage => _currentPage;

  int get totalPages => _totalPages;

  int get totalElements => _totalElements;

  int get pageSize => _pageSize;
  bool _isInitialized = false;

  DateTime? _selectedDate;

  DateTime? get selectedDate => _selectedDate;

  set selectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchAllSkedsPaged(page: 0, size: 20);
    _isInitialized = true;
  }

  Future<Sked> updateSked(Sked sked) async {
    try {
      final updatedSked = await ApiService().updateSked(
        sked.id,
        skedNumber: sked.skedNumber,
        departmentId: sked.departmentId,
        employeeId: sked.employeeId,
        assetCategory: sked.assetCategory,
        dateReceived: sked.dateReceived,
        itemName: sked.itemName,
        serialNumber: sked.serialNumber,
        count: sked.count,
        measure: sked.measure,
        price: sked.price,
        place: sked.place,
        comments: sked.comments,
        available: sked.available,
      );

      // ОБНОВЛЯЕМ локальные данные и УВЕДОМЛЯЕМ слушателей
      final index = _skeds.indexWhere((s) => s.id == sked.id);
      if (index != -1) {
        _skeds[index] = updatedSked;
        notifyListeners(); // ← ВАЖНО: уведомляем об изменении
      }

      // только отправка по сокету
      _wsService.pushManualChange(sked.id, sked.available);

      return updatedSked;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSked(int skedId) async {
    try {
      _startLoading();
      await ApiService().deleteSked(skedId);

      // Удаляем из локального списка
      _skeds.removeWhere((sked) => sked.id == skedId);
      _totalElements--; // Уменьшаем общее количество элементов

      _clearError();
      notifyListeners();

    } catch (e) {
      _handleError('Ошибка при удалении', e);
    } finally {
      _stopLoading();
    }
  }

  void clearSkeds() {
    _skeds.clear();
    _currentDepartmentId = null;
    notifyListeners();
  }

  Future<Sked> createSked({
    required int departmentId,
    required int employeeId,
    required String assetCategory,
    required DateTime dateReceived,
    required String itemName,
    required String serialNumber,
    required int count,
    required String place,
    required String measure,
    required double price,
    required String comments,
  }) async {
    try {
      _startLoading();

      final newSked = await ApiService().createSked(
        departmentId: departmentId,
        employeeId: employeeId,
        assetCategory: assetCategory,
        dateReceived: dateReceived,
        itemName: itemName,
        serialNumber: serialNumber,
        count: count,
        measure: measure,
        price: price,
        place: place,
        comments: comments,
      );

      _skeds.add(newSked);
      _clearError();
      notifyListeners();

      return newSked;
    } catch (e) {
      _handleError('Failed to create sked', e);
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Future<Sked> moveSkedToDepartment({
    required int skedId,
    required int newDepartmentId,
    required DateTime newDateReceived,
    required String newPlace,
    required int newEmployeeId,
  }) async {
    try {
      _startLoading();

      final sked = _skeds.firstWhere((s) => s.id == skedId);

      // Проверка на повторное перемещение
      if (sked.comments.contains('Перемещено в')) {
        throw Exception('Это имущество уже было перемещено ранее!');
      }

      final departments = departmentProvider.departments;

      final fromDepartment = departments.firstWhere(
            (d) => d.id == sked.departmentId,
        orElse: () =>
            Department(id: sked.departmentId, name: 'ID ${sked.departmentId}'),
      );

      final toDepartment = departments.firstWhere(
            (d) => d.id == newDepartmentId,
        orElse: () =>
            Department(id: newDepartmentId, name: 'ID $newDepartmentId}'),
      );

      // Создаём новую запись с обновлёнными данными
      final movedSked = await ApiService().createSked(
        departmentId: newDepartmentId,
        employeeId: newEmployeeId,
        assetCategory: sked.assetCategory,
        dateReceived: newDateReceived,
        itemName: sked.itemName,
        serialNumber: sked.serialNumber,
        count: sked.count,
        measure: sked.measure,
        price: sked.price,
        place: newPlace,
        comments: 'Перемещено из ${fromDepartment.name}. ${sked.comments}',
      );

      // УДАЛЯЕМ исходную запись (как при списании)
      await ApiService().deleteSked(skedId);

      // Обновляем локальные данные
      _skeds.removeWhere((s) => s.id == skedId);
      _skeds.add(movedSked);
      _totalElements--; // Уменьшаем общее количество

      _clearError();
      notifyListeners();
      return movedSked;
    } catch (e) {
      _handleError('Ошибка перемещения SKED $skedId: $e', e);
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Future<void> writeOffSked({
  //   required int skedId,
  //   required String writeOffReason,
  // }) async {
  //   try {
  //     _startLoading();
  //
  //     // ВАЖНО: Для вашего бэкенда списание = УДАЛЕНИЕ
  //     await deleteSked(skedId); // Используем существующий метод удаления
  //
  //     _clearError();
  //     notifyListeners();
  //
  //   } catch (e) {
  //     _handleError('Ошибка списания SKED $skedId: $e', e);
  //     rethrow;
  //   } finally {
  //     _stopLoading();
  //   }
  // }

  Future<void> releaseSkedNumber(int skedId) async {
    try {
      _startLoading();

      // Вместо удаления отправляем запрос на освобождение номера
      await ApiService().releaseSkedNumber(skedId);

      // Обновляем локально: помечаем запись и очищаем номер
      final index = _skeds.indexWhere((s) => s.id == skedId);
      if (index != -1) {
        _skeds[index] = _skeds[index].copyWith(
          numberReleased: true,
          skedNumber: null, // Очищаем номер
        );
      }

      _clearError();
      notifyListeners();

    } catch (e) {
      _handleError('Ошибка освобождения номера', e);
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Future<void> fetchSkedsByDepartment(int departmentId) async {
    if (_isLoading || _currentDepartmentId == departmentId) return;

    try {
      _startLoading();
      _currentDepartmentId = departmentId;

      final response = await ApiService().fetchSkedsByDepartment(departmentId);
      _skeds = response;
      _clearError();
    } catch (e) {
      _handleError('Failed to load skeds for department $departmentId', e);
    } finally {
      _stopLoading();
    }
  }

  Future<List<Sked>> fetchAllSkedsRaw({int? departmentId}) async {
    if (departmentId != null) {
      return await ApiService().fetchSkedsByDepartment(departmentId);
    } else {
      return await ApiService().fetchAllSkeds();
    }
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleError(String message, dynamic error) {
    _errorMessage = message;
    debugPrint('Error: $message, $error');
  }

  void clearError() {
    _skeds = [];
    notifyListeners();
  }

  Future<void> fetchAllSkedsPaged({
    int? page,
    int? size,
    String? sort,
  }) async {
    if (_isLoading) return;

    try {
      _startLoading();
      _currentDepartmentId = null;

      final response = await ApiService().fetchAllSkedsPaged(
        page: page ?? _currentPage,
        size: size ?? _pageSize,
        sort: sort ?? _currentSort,
      );

      _skeds = response.content;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _currentPage = response.number;
      _pageSize = response.size;
      _currentSort = sort;

      _clearError();
    } catch (e) {
      _handleError('Failed to load all skeds', e);
      _skeds = [];
    } finally {
      _stopLoading();
      notifyListeners(); // переместили сюда
    }
  }

  Future<void> fetchSkedsByDepartmentPaged({
    required int departmentId,
    int? page,
    int? size,
    String? sort,
  }) async {
    if (_isLoading) return;

    try {
      _startLoading();
      _currentDepartmentId = departmentId;

      final response = await ApiService().fetchSkedsByDepartmentPaged(
        departmentId: departmentId,
        page: page ?? _currentPage,
        size: size ?? _pageSize,
        sort: sort ?? _currentSort,
      );

      _skeds = response.content;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _currentPage = response.number;
      _pageSize = response.size;
      _currentSort = sort;

      _clearError();
      print(
          "DEPT $departmentId | Total: $_totalElements | Page: $_currentPage/$_totalPages");
    } catch (e) {
      _handleError('Failed to load skeds for department $departmentId', e);
    } finally {
      _stopLoading();
      notifyListeners();
    }
  }

  Future<void> writeOffSked({
    required int skedId,
    required String writeOffReason,
  }) async {
    try {
      _startLoading();

      // Используем новый endpoint для списания с причиной
      await ApiService().writeOffSked(skedId, writeOffReason);

      // Обновляем локальные данные
      _skeds.removeWhere((s) => s.id == skedId);
      _totalElements--;

      _clearError();
      notifyListeners();

    } catch (e) {
      _handleError('Ошибка списания SKED $skedId: $e', e);
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Future<List<SkedHistory>> getSkedHistory(int skedId) async {
    try {
      return await ApiService().getSkedHistory(skedId);
    } catch (e) {
      _handleError('Ошибка получения истории', e);
      rethrow;
    }
  }
}
