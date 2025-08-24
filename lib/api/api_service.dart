import 'package:dio/dio.dart';

import '../models/Department.dart';
import '../models/Employee.dart';
import '../models/Binding.dart';
import '../models/Sked.dart';
import '../models/SkedHistory.dart';
import '../screens/sked_screen/pagination_response.dart';
import 'api_service_binding.dart';
import 'api_service_department.dart';
import 'api_service_employee.dart';
import 'api_service_sked.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8060/api'));
  // final Dio _dio = Dio(BaseOptions(baseUrl: 'https://inventory-3z06.onrender.com/api'));

  late final DepartmentService _departmentService;
  late final EmployeeService _employeeService;
  late final BindingService _bindingService;
  late final SkedService _skedService;

  ApiService() {
    // Инициализируем сервисы с общим Dio клиентом
    _departmentService = DepartmentService(_dio);
    _employeeService = EmployeeService(_dio);
    _bindingService = BindingService(_dio);
    _skedService = SkedService(_dio);
  }

  Future<List<Department>> fetchDepartments() => _departmentService.fetchDepartments();

  Future<List<Employee>> fetchEmployees() => _employeeService.fetchEmployees();

  Future<List<Binding>> fetchBindings() => _bindingService.fetchBindings();

  Future<Sked> updateSked(
      int skedId, {
        required String skedNumber,
        required int departmentId,
        required int employeeId,
        required String assetCategory,
        required DateTime dateReceived,
        required String itemName,
        required String serialNumber,
        required int count,
        required String measure,
        required double price,
        required String place,
        required String comments,
        required bool available,
      }) => _skedService.updateSked(
    skedId,
    skedNumber: skedNumber,
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
    available: available,
  );

  Future<Sked> createSked({
    required int departmentId,
    required int employeeId,
    required String assetCategory,
    required DateTime dateReceived,
    required String itemName,
    required String serialNumber,
    required int count,
    required String measure,
    required double price,
    required String place,
    required String comments,
    bool available = false,
  }) => _skedService.createSked(
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
    available: available,
  );

  Future<void> deleteSked(int skedId) => _skedService.deleteSked(skedId);

  Future<PaginationResponse<Sked>> fetchAllSkedsPaged({
    int page = 0,
    int size = 20,
    String? sort,
  }) => _skedService.fetchAllSkedsPaged(page: page, size: size, sort: sort);

  Future<PaginationResponse<Sked>> fetchSkedsByDepartmentPaged({
    required int departmentId,
    int page = 0,
    int size = 20,
    String? sort,
  }) => _skedService.fetchSkedsByDepartmentPaged(
    departmentId: departmentId,
    page: page,
    size: size,
    sort: sort,
  );

  Future<List<Sked>> fetchAllSkeds() => _skedService.fetchAllSkeds();

  Future<List<Sked>> fetchSkedsByDepartment(int departmentId) =>
      _skedService.fetchSkedsByDepartment(departmentId);

  Future<void> releaseSkedNumber(int skedId) => _skedService.releaseSkedNumber(skedId);

  Future<void> writeOffSked(int skedId, String reason) =>
      _skedService.writeOffSked(skedId, reason);

  Future<List<SkedHistory>> getSkedHistory(int skedId) =>
      _skedService.getSkedHistory(skedId);

  Future<Sked> transferSked(int skedId, int newDepartmentId, String reason) =>
      _skedService.transferSked(skedId, newDepartmentId, reason);
}
