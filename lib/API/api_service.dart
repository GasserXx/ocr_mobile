import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'token_service.dart';
import 'package:untitled17/models/receipt_type_model.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:math' as math;

class ApiService {
  static const String baseUrl = 'https://invizo-app.koyeb.app';

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

      if (response.statusCode == 524) {
        throw Exception('Server is temporarily unavailable. Please try again later.');
      }

      // Try to parse response body only if it's valid JSON
      try {
        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          if (responseData['token'] != null) {
            await TokenService.saveToken(responseData['token']);
          }
          return responseData;
        } else {
          final errorMessage = responseData['messageCode'] ??
              responseData['response'] ??
              'Failed to login';
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Server error. Please try again later.');
        }
        rethrow;
      }
    } catch (e) {
      print('Login error: $e');
      if (e is SocketException) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception(e.toString()
          .replaceAll('Exception:', '')
          .replaceAll('FormatException:', '')
          .trim());
    }
  }

  static Future<List<ReceiptType>> getReceiptTypes() async {
    try {
      final token = await TokenService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/receipt-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Receipt Types Response:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) {
          print('Processing receipt type:');
          print('Raw item: $item');
          return ReceiptType.fromJson(item);
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['response'] ?? 'Failed to load receipt types');
      }
    } catch (e) {
      print('Error fetching receipt types: $e');
      throw Exception('Failed to load receipt types: $e');
    }
  }

  static Future<bool> uploadReceiptImages(String receiptTypeId, List<String> base64Images) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/request/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add receipt type ID as a field
      request.fields['receiptTypeId'] = receiptTypeId;

      // Add files
      for (int i = 0; i < base64Images.length; i++) {
        final bytes = base64Decode(base64Images[i]);
        final multipartFile = http.MultipartFile.fromBytes(
          'files',  // field name
          bytes,
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      print('Sending multipart request...');
      print('Receipt Type ID: $receiptTypeId');
      print('Number of files: ${base64Images.length}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['response'] ?? 'Failed to upload images');
      }
    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }

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