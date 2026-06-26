import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class CartManager {
  static const String _key = 'saved_cart_items';

  static Future<void> saveCart(Map<String, CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();

    final data = cart.map((key, item) {
      final p = item.product;

      return MapEntry(key, {
        'quantity': item.quantity,
        'product': {
          'title': p.title,
          'price': p.price,
          'oldPrice': p.oldPrice,
          'discountPercent': p.discountPercent,
          'description': p.description,
          'shortDescription': p.shortDescription,
          'images': p.images,
          'category': p.category,
          'sku': p.sku,
          'stock': p.stock,
          'dateCreated': p.dateCreated,
          'dateModified': p.dateModified,
        },
      });
    });

    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<Map<String, CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    return decoded.map((key, value) {
      final item = value as Map<String, dynamic>;
      final p = item['product'] as Map<String, dynamic>;

      final product = Product(
        id: p['id'] ?? '',
        title: p['title'] ?? '',
        price: p['price'] ?? '',
        oldPrice: p['oldPrice'] ?? '',
        discountPercent: p['discountPercent'] ?? 0,
        description: p['description'] ?? '',
        shortDescription: p['shortDescription'] ?? '',
        images: List<String>.from(p['images'] ?? []),
        category: p['category'] ?? '',
        sku: p['sku'] ?? '',
        stock: p['stock'] ?? '',
        dateCreated: p['dateCreated'] ?? '',
        dateModified: p['dateModified'] ?? '',
      );

      return MapEntry(
        key,
        CartItem(
          product: product,
          quantity: item['quantity'] ?? 1,
        ),
      );
    });
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}