import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_service.dart';
import 'package:untitled17/API/receipt_type_model.dart';

class ApiService {
  static const String baseUrl = 'https://invizo-app.koyeb.app';

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      print('Attempting to register with email: $email');
      print('Request URL: $baseUrl/auth/register');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save token if it's provided with registration
        if (responseData['token'] != null) {
          await TokenService.saveToken(responseData['token']);
        }
        return responseData;
      } else {
        throw Exception(responseData['messageCode'] ?? responseData['response'] ?? 'Failed to register');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<void> sendForgotPasswordEmail(String email) async {
    try {
      print('Attempting to send reset link to email: $email');
      print('Request URL: $baseUrl/auth/send-forgot-password');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['messageCode'] ?? responseData['response'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('Send reset link error: $e');
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting to login with email: $email');
      print('Request URL: $baseUrl/auth/login');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save the token when login is successful
        if (responseData['token'] != null) {
          await TokenService.saveToken(responseData['token']);
        }
        return responseData;
      } else {
        final errorMessage = responseData['messageCode'] ?? responseData['response'] ?? 'Failed to login';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  static Future<List<ReceiptType>> getReceiptTypes() async {
    try {
      print('Fetching receipt types');
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/receipt-types'),
        headers: headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((name) => ReceiptType.fromJson(name.toString())).toList();
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        await TokenService.deleteToken(); // Clear invalid token
        throw Exception('Session expired. Please login again');
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to load receipt types');
      }
    } catch (e) {
      print('Error fetching receipt types: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Simple method to handle local logout
  static Future<void> logout() async {
    try {
      await TokenService.deleteToken();
      print('Local logout successful');
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Error clearing local session');
    }
  }
}