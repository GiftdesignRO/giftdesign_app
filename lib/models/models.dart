import 'package:flutter/material.dart';

class Product {
  final String title;
  final String price;
  final String description;
  final String shortDescription;
  final List<String> images;
  final String category;
  final String sku;
  final String stock;
  final String dateCreated;
  final String dateModified;

  Product({
    required this.title,
    required this.price,
    required this.description,
    required this.shortDescription,
    required this.images,
    required this.category,
    required this.sku,
    required this.stock,
    required this.dateCreated,
    required this.dateModified,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final List<String> uniqueImages = [];

    void addImage(dynamic value) {
      final url = value?.toString().trim() ?? '';

      if (url.isEmpty) return;

      // Avoid duplicates caused by MerchantPro returning the same image
      // in multiple sizes/structures.
      final normalized = url
          .replaceAll(RegExp(r'_(thumb|medium|large)(?=\.)'), '')
          .replaceAll(RegExp(r'/[tmh]/(?=[^/]+$)'), '/');

      final alreadyExists = uniqueImages.any((existing) {
        final existingNormalized = existing
            .replaceAll(RegExp(r'_(thumb|medium|large)(?=\.)'), '')
            .replaceAll(RegExp(r'/[tmh]/(?=[^/]+$)'), '/');

        return existing == url || existingNormalized == normalized;
      });

      if (!alreadyExists) {
        uniqueImages.add(url);
      }
    }

    // Prefer the real product gallery first. This avoids repeating the cover
    // image that also appears in image_url/thumb/medium.
    if (json['images'] is List) {
      for (final image in json['images']) {
        if (image is Map) {
          addImage(image['url']);
        }
      }
    }

    // Fallback only if the gallery is empty.
    if (uniqueImages.isEmpty) {
      addImage(json['image_url']?['medium']);
      addImage(json['image_url']?['thumb']);
    }

    String cleanHtml(dynamic value) {
      final raw = value?.toString() ?? '';

      if (raw.trim().isEmpty) return '';

      return raw
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&icirc;', 'î')
          .replaceAll('&Icirc;', 'Î')
          .replaceAll('&acirc;', 'â')
          .replaceAll('&Acirc;', 'Â')
          .replaceAll('&ă;', 'ă')
          .replaceAll('&Ă;', 'Ă')
          .replaceAll('&ș;', 'ș')
          .replaceAll('&Ș;', 'Ș')
          .replaceAll('&ț;', 'ț')
          .replaceAll('&Ț;', 'Ț')
          .replaceAll(RegExp(r'\n[ \t]+'), '\n')
          .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    }

    final metaFields = json['meta_fields'];
    final meta = metaFields is Map ? metaFields : const {};

    final shortDesc = cleanHtml(
      meta['short_desc'] ??
          meta['short_description'] ??
          meta['shortDesc'] ??
          json['short_desc'] ??
          json['short_description'] ??
          json['shortDesc'] ??
          json['meta_description'] ??
          json['meta_desc'],
    );

    final longDesc = cleanHtml(
      meta['description'] ??
          meta['description_html'] ??
          meta['full_description'] ??
          json['description'] ??
          json['description_html'] ??
          json['desc'] ??
          json['content'] ??
          json['product_description'],
    );

    final bestDescription = longDesc.isNotEmpty
        ? longDesc
        : shortDesc.isNotEmpty
            ? shortDesc
            : 'Descriere indisponibilă momentan';

    return Product(
      title: json['name']?.toString() ?? 'Produs GiftDesign',
      price: '${json['price_gross'] ?? json['price'] ?? ''} Lei',
      description: bestDescription,
      shortDescription: shortDesc,
      images: uniqueImages,
      category: json['category_name']?.toString() ?? 'Diverse',
      sku: json['sku']?.toString() ?? '',
      stock: json['stock']?.toString() ?? '',
      dateCreated: json['date_created']?.toString() ?? '',
      dateModified: json['date_modified']?.toString() ?? '',
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get unitPrice {
    final cleaned = product.price
        .replaceAll('Lei', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9\.-]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  double get total => unitPrice * quantity;
}


class CategoryGroup {
  final String title;
  final IconData icon;
  final List<String> subcategories;

  const CategoryGroup({required this.title, required this.icon, required this.subcategories});
}


class CategoryData {
  final int id;
  final String name;
  final int parentId;
  final String menuImage;
  final String imageSubcategory;
  final String menuIcon;

  const CategoryData({
    required this.id,
    required this.name,
    required this.parentId,
    required this.menuImage,
    required this.imageSubcategory,
    required this.menuIcon,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    String imageUrl(dynamic value) {
      if (value == null) return '';

      if (value is String) return value.trim();

      if (value is Map) {
        final candidates = [
          value['url'],
          value['path'],
          value['src'],
          value['large'],
          value['medium'],
          value['thumb'],
          value['name'],
        ];

        for (final candidate in candidates) {
          final text = candidate?.toString().trim() ?? '';
          if (text.startsWith('http')) return text;
        }

        for (final entry in value.values) {
          final text = entry?.toString().trim() ?? '';
          if (text.startsWith('http')) return text;
        }
      }

      return '';
    }

    int readInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CategoryData(
      id: readInt(json['id']),
      name: json['name']?.toString() ?? '',
      parentId: readInt(json['parent_id']),
      menuImage: imageUrl(json['menu_image']),
      imageSubcategory: imageUrl(json['image_subcategory']),
      menuIcon: imageUrl(json['menu_icon']),
    );
  }
}
