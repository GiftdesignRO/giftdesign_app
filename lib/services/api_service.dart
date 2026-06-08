import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/models.dart';
import 'session_service.dart';

class ApiService {
  const ApiService._();

  static Future<Map<String, String>> authHeaders() async {
    final user = await SessionService.loadUser();

    final token = user['token'];
    // print('🔥🔥🔥 USER DATA: $user');
    // print('🔥🔥🔥 TOKEN: $token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/products'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nu am putut încărca produsele din MerchantPro');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((item) => Product.fromJson(item)).toList();
  }

  static Future<List<CategoryData>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/categories'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nu am putut încărca categoriile din MerchantPro');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => CategoryData.fromJson(item))
        .where((category) => category.name.trim().isNotEmpty)
        .toList();
  }

  static Future<http.Response> register({
    required String name,
    required String email,
    required String password,
  }) {
    return http.post(
      Uri.parse('$apiBaseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> login({
    required String email,
    required String password,
  }) {
    return http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }


  static Future<List<dynamic>> fetchOrders() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/orders'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nu am putut încărca comenzile.');
    }

    final decoded = jsonDecode(response.body);

    return decoded['data'] ?? [];
  }
static Future<Map<String, dynamic>> cancelOrder(
  String orderId, {
  required String reason,
  String customReason = '',
}) async {
  final response = await http.put(
    Uri.parse('$apiBaseUrl/orders/$orderId/cancel'),
    headers: {
      ...(await authHeaders()),
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'reason': reason,
      'custom_reason': customReason,
    }),
  );

  final decoded = jsonDecode(response.body);

  if (response.statusCode != 200) {
    throw Exception(
      decoded['error'] ??
          'Nu am putut anula comanda.',
    );
  }

  return decoded;
}
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/profile'),
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] ?? 'Nu am putut încărca profilul.',
      );
    }

    return decoded;
  }

    static Future<Map<String, dynamic>> saveProfile({
    required Map<String, dynamic> profile,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/profile'),
      headers: await authHeaders(),
      body: jsonEncode(profile),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] ?? 'Nu am putut salva profilul.',
      );
    }

    return decoded;
  }

  static Future<List<dynamic>> fetchAdminUsers() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/admin/users'),
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] ?? 'Nu am putut încărca utilizatorii.',
      );
    }

    return decoded['users'] ?? [];
  }

  static Future<Map<String, dynamic>> updateAdminUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/admin/users/$userId'),
      headers: await authHeaders(),
      body: jsonEncode(userData),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] ?? 'Nu am putut actualiza utilizatorul.',
      );
    }

    return decoded;
  }
}
