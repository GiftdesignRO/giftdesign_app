import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';

class ActivityPage extends StatelessWidget {
  final String title;
  final List<Product> products;
  final List<String> searches;
  final Function(Product) onProductTap;
  final Function(String) onSearchTap;

  const ActivityPage({
    super.key,
    required this.title,
    this.products = const [],
    this.searches = const [],
    required this.onProductTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSearchPage = searches.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0F12)
          : null,
      appBar: AppBar(title: Text(title)),
      body: isSearchPage ? buildSearches(context) : buildProducts(context),
    );
  }

  Widget buildProducts(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Nu există produse aici încă.'));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        130 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final image = product.images.isNotEmpty ? product.images.first : '';

        return Card(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B1B20)
              : null,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            onTap: () => onProductTap(product),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.isEmpty
                  ? Container(
                      width: 62,
                      height: 62,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A32) : Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
            ),
            title: Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              product.price,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
        );
      },
    );
  }

  Widget buildSearches(BuildContext context) {
    if (searches.isEmpty) {
      return const Center(child: Text('Nu există căutări încă.'));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        130 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: searches.length,
      itemBuilder: (context, index) {
        final query = searches[index];

        return Card(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B1B20)
              : null,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () => onSearchTap(query),
            leading: const Icon(Icons.search, color: primaryColor),
            title: Text(
              query,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
        );
      },
    );
  }
}