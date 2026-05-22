import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/models.dart';

class ApiService {
  const ApiService._();

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/products'));

    if (response.statusCode != 200) {
      throw Exception('Nu am putut încărca produsele din MerchantPro');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((item) => Product.fromJson(item)).toList();
  }

  static Future<List<CategoryData>> fetchCategories() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));

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
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
  }

  static Future<http.Response> login({
    required String email,
    required String password,
  }) {
    return http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }
}
