import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String baseUrl = "http://172.16.6.10:8000/api"; // Change this to your Django backend URL

  static Future<Map<String, dynamic>?> insertUser(Map<String, String> userData) async {
    final Uri url = Uri.parse("$baseUrl/register/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.body}"};
      }
    } catch (e) {
      return {"message": "Error: $e"};
    }
  }

  // New function to send shop details to Django backend
  static Future<Map<String, dynamic>?> addShop(Map<String, dynamic> shopData) async {
    final Uri url = Uri.parse("$baseUrl/add-shop/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(shopData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.body}"};
      }
    } catch (e) {
      return {"message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>?> fetchShopDetails() async {
    final Uri url = Uri.parse("$baseUrl/vendor-shop/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to fetch data"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }

  // Save Shop Details (POST request)
  static Future<Map<String, dynamic>?> saveShopDetails(Map<String, dynamic> shopData) async {
    final Uri url = Uri.parse("$baseUrl/vendor-shop/save/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(shopData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to save data"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }

  // Request password reset (works for both email and phone)
  static Future<Map<String, dynamic>> requestPasswordReset(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/request/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Failed to request password reset'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}'
      };
    }
  }


  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/verify-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Failed to verify OTP'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

// Set new password
  static Future<Map<String, dynamic>> setNewPassword(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/set-new-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}'
      };
    }
  }
}
