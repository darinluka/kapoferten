import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import '../models/notification_model.dart';

class ApiService {
  // Connect to the local computer network IP
  static const String baseUrl = 'http://192.168.18.241:3001';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Authentication ---
  
  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['accessToken'] as String);
      await prefs.setString('userId', data['userId'] as String);
      await prefs.setString('email', data['email'] as String);
      return true;
    }
    return false;
  }

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['accessToken'] as String);
      await prefs.setString('userId', data['userId'] as String);
      await prefs.setString('email', data['email'] as String);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('email');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      await http.patch(
        Uri.parse('$baseUrl/auth/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (e) {
      print('Failed to send FCM token to backend: $e');
    }
  }

  static Future<bool> updateProfile({String? email, String? password}) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      if (body.isEmpty) return true;

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if (data['email'] != null) {
          await prefs.setString('email', data['email'] as String);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }

  // --- Alerts CRUD ---

  static Future<List<AlertModel>> getAlerts() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/alerts'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => AlertModel.fromJson(item)).toList();
    }
    throw Exception('Gabim në ngarkimin e alerteve.');
  }

  static Future<AlertModel> createAlert({
    required String title,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? city,
    String? category,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/alerts'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'keyword': keyword,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'city': city,
        'category': category,
      }),
    );

    if (response.statusCode == 201) {
      return AlertModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Dështoi krijimi i alertit.');
  }

  static Future<AlertModel> toggleAlertActive(String id, bool isActive) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/alerts/$id'),
      headers: headers,
      body: jsonEncode({'isActive': isActive}),
    );

    if (response.statusCode == 200) {
      return AlertModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Dështoi ndryshimi i gjendjes së alertit.');
  }

  static Future<bool> deleteAlert(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/alerts/$id'), headers: headers);

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // --- Notifications History ---

  static Future<List<NotificationModel>> getNotifications() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => NotificationModel.fromJson(item)).toList();
    }
    throw Exception('Gabim në ngarkimin e njoftimeve.');
  }

  static Future<void> markAsRead(String id) async {
    final headers = await _getHeaders();
    await http.patch(Uri.parse('$baseUrl/notifications/$id/read'), headers: headers);
  }

  static Future<void> markAllAsRead() async {
    final headers = await _getHeaders();
    await http.patch(Uri.parse('$baseUrl/notifications/read-all'), headers: headers);
  }
}
