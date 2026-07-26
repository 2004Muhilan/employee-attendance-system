import 'package:flutter/material.dart';
import '../models/employee_model.dart';

class EmployeeProvider with ChangeNotifier {
  Employee? _employee;
  String? _authToken; // Added: Store the token here
  bool _isLoading = false;

  // Getters
  Employee? get employee => _employee;
  String? get authToken => _authToken; // Added getter
  bool get isLoading => _isLoading;

  // Setters
  void setEmployee(Employee emp) {
    _employee = emp;
    notifyListeners();
  }

  // Added: Setter for Token
  void setToken(String token) {
    _authToken = token;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear data on Logout
  void clearEmployee() {
    _employee = null;
    _authToken = null; // Added: Clear token
    notifyListeners();
  }
}