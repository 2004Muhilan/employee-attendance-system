import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/employee_model.dart';
import '../models/office_model.dart';
import '../models/attendance_model.dart';

class ApiService {

  Future<Map<String, dynamic>> submitRegistration({
    required String fullName,
    required String email,
    required String phone,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    // Assuming ApiConstants.baseUrl is "http://127.0.0.1:5000"
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/register');

    try {
      var request = http.MultipartRequest('POST', url);

      // Attach text fields
      request.fields['full_name'] = fullName;
      request.fields['email'] = email;
      request.fields['phone'] = phone;

      // Attach image file if provided
      if (imageBytes != null && imageName != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'profile_image',
          imageBytes,
          filename: imageName,
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData; // Return the success message
      } else {
        throw responseData['error'] ?? 'Registration failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Fetch Employee Profile by exchanging Firebase Token
  Future<Employee?> fetchUserProfile(String token) async {
    // 1. Construct URL (/auth/login)
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

    try {
      // 2. CHANGED: Use POST instead of GET
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Note: We don't need the Authorization header anymore
          // because your Python code looks in the body for 'id_token'
        },
        // 3. CHANGED: Send token in the Body
        body: jsonEncode({
          "id_token": token,
        }),
      );

      print("📡 Flask Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // 4. CHANGED: Unwrap the response
        // Your Python returns: { "status": "success", "data": { ... } }
        // We need to grab the 'data' part.
        final userData = jsonResponse['data'];

        return Employee.fromJson(userData);
      }

      // Handle Specific Errors based on your Python code
      else if (response.statusCode == 401) {
        throw 'Session expired or invalid token.';
      } else if (response.statusCode == 404) {
        throw 'User profile not found. Please contact HR.';
      } else if (response.statusCode == 403) {
        throw 'Account is disabled. Contact Admin.';
      } else {
        throw 'Server Error: ${response.statusCode}';
      }
    } catch (e) {
      print("❌ API Error: $e");
      throw e.toString();
    }
  }

  // --- GEOFENCE METHODS ---
  Future<OfficeModel> getOfficeGeofence(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/${ApiConstants.officeGeofenceEndpoint}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id_token": token}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OfficeModel.fromJson(json['data']);
    } else {
      throw 'Failed to load office location';
    }
  }

  Future<Map<String, dynamic>> getAttendanceHistory(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/${ApiConstants.attendanceHistoryEndpoint}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id_token": token}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'];

      // Parse List
      List<AttendanceRecord> records = (data['history'] as List)
          .map((e) => AttendanceRecord.fromJson(e))
          .toList();

      return {
        "records": records,
        "joining_date": data['joining_date']
      };
    } else {
      throw 'Failed to fetch history';
    }
  }

  Future<Map<String, dynamic>> getAttendanceStatus(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/attendance/today-status');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id_token": token}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // The backend wraps the result in a "data" key
        return json['data'];
      } else {
        // Handle server errors (400, 401, 500)
        final errorJson = jsonDecode(response.body);
        throw errorJson['error'] ?? 'Failed to fetch attendance status';
      }
    } catch (e) {
      throw 'Connection error: $e';
    }
  }

  Future<Map<String, dynamic>> markCheckIn(String token, double lat, double lng) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCheckInEndpoint}');

    return _sendAttendanceRequest(url, token, lat, lng);
  }

  Future<Map<String, dynamic>> markCheckOut(String token, double lat, double lng) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCheckOutEndpoint}');

    return _sendAttendanceRequest(url, token, lat, lng);
  }

  // Helper to avoid duplicate code
  Future<Map<String, dynamic>> _sendAttendanceRequest(Uri url, String token, double lat, double lng) async {
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id_token": token,
          "latitude": lat,
          "longitude": lng,
        }),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return json; // Success
      } else {
        throw json['error'] ?? 'Action failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // --- LEAVE METHODS ---
  Future<Map<String, dynamic>> submitLeave(String token, Map<String, dynamic> leaveData) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveSubmitEndpoint}');
    
    // Add token to the payload
    leaveData['id_token'] = token;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(leaveData),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json; // Success
      } else {
        throw json['message'] ?? json['error'] ?? 'Failed to submit leave';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<List<dynamic>> getLeaveHistory(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveHistoryEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id_token": token}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as List<dynamic>? ?? [];
      } else {
        throw json['message'] ?? json['error'] ?? 'Failed to fetch history';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}