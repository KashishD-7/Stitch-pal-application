import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://172.16.6.10:8000/api/measurements/";

class MeasurementService {
  // Get User Token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch Measurements
  static Future<List<Map<String, dynamic>>> fetchMeasurements() async {
    String? token = await getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch measurements");
    }
  }

  // Add Measurement
  static Future<bool> addMeasurement(Map<String, dynamic> measurementData) async {
    String? token = await getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: json.encode(measurementData),
    );

    return response.statusCode == 201;
  }

  // Edit Measurement
  static Future<bool> editMeasurement(int id, Map<String, dynamic> updatedData) async {
    String? token = await getToken();
    final response = await http.put(
      Uri.parse("$baseUrl$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: json.encode(updatedData),
    );

    return response.statusCode == 200;
  }

  // Delete Measurement
  static Future<bool> deleteMeasurement(int id) async {
    String? token = await getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 204;
  }
}
