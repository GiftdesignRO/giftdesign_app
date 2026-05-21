import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';

class ProductPage extends StatefulWidget {
  final Product product;
  final Function(Product) onAddToCart;
  final Function(Product) onToggleFavorite;
  final bool isFavorite;

  const ProductPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int currentImageIndex = 0;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.product.images.isNotEmpty
    ? widget.product.images
    : [''];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: primaryColor),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
              widget.onToggleFavorite(widget.product);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 360,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = images[index];
                return image.isEmpty
                    ? Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 80)))
                    : Image.network(image, width: double.infinity, fit: BoxFit.cover);
              },
            ),
          ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text('${currentImageIndex + 1}/${images.length}', style: TextStyle(color: Colors.grey.shade700)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.product.category, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.product.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text(widget.product.price, style: const TextStyle(color: primaryColor, fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (widget.product.sku.isNotEmpty) Text('SKU: ${widget.product.sku}'),
              if (widget.product.stock.isNotEmpty) Text('Stoc: ${widget.product.stock}'),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => widget.onAddToCart(widget.product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Adaugă în coș', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 26),
              const Text('Descriere', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                widget.product.description.isNotEmpty
                    ? widget.product.description
                    : widget.product.shortDescription.isNotEmpty
                        ? widget.product.shortDescription
                        : 'Descriere indisponibilă momentan.',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
