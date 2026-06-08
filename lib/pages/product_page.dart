import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../models/models.dart';

class ProductPage extends StatefulWidget {
  final Product product;
  final Function(Product, int) onAddToCart;
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
  bool descriptionExpanded = false;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  String get heroTag =>
      widget.product.sku.isNotEmpty ? widget.product.sku : widget.product.title;

  int get stockValue {
    final parsed = int.tryParse(widget.product.stock.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  bool get hasStock => stockValue > 0;

  String get productDescription => widget.product.description.isNotEmpty
      ? widget.product.description
      : widget.product.shortDescription.isNotEmpty
      ? widget.product.shortDescription
      : 'Descriere indisponibilă momentan.';

  void handleAddToCart() {
    if (!hasStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produsul nu este disponibil momentan.'),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onAddToCart(widget.product, quantity);
  }

  void handleToggleFavorite() {
    HapticFeedback.selectionClick();
    setState(() {
      isFavorite = !isFavorite;
    });
    widget.onToggleFavorite(widget.product);
  }

  Widget priceSection({double priceSize = 32, double oldPriceSize = 18}) {
    final product = widget.product;
    final hasDiscount =
        product.oldPrice.isNotEmpty && product.discountPercent > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount) ...[
          Row(
            children: [
              Flexible(
                child: Text(
                  product.oldPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: oldPriceSize,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          product.price,
          style: TextStyle(
            color: hasDiscount ? Colors.red : primaryColor,
            fontSize: priceSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget imagePlaceholder({double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 72, color: Colors.grey),
      ),
    );
  }

  Widget imageGallery(List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 390,
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
                  ? imagePlaceholder(height: 390)
                  : Hero(
                      tag: heroTag,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 3,
                        child: CachedNetworkImage(
                          imageUrl: image,
                          width: double.infinity,
                          height: 390,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 350),
                          placeholder: (_, __) => imagePlaceholder(height: 390),
                          errorWidget: (_, __, ___) =>
                              imagePlaceholder(height: 390),
                        ),
                      ),
                    );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                    Colors.black.withOpacity(0.22),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.product.discountPercent > 0)
          Positioned(
            left: 18,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                '-${widget.product.discountPercent}% reducere',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (images.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: imageDots(images.length),
          ),
      ],
    );
  }

  Widget imageDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = currentImageIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget trustBadges() {
    final icons = [
      Icons.local_shipping_outlined,
      Icons.verified_user_outlined,
      Icons.replay_rounded,
    ];
    final titles = ['Livrare rapidă', 'Plată sigură', 'Retur simplu'];
    final subtitles = ['24-48h', 'securizată', '14 zile'];

    return Row(
      children: List.generate(icons.length, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryColor.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                Icon(icons[index], color: primaryColor, size: 24),
                const SizedBox(height: 7),
                Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget productMeta() {
    final chips = <Widget>[];

    if (widget.product.sku.isNotEmpty) {
      chips.add(metaChip(Icons.qr_code_rounded, 'SKU ${widget.product.sku}'));
    }

    if (widget.product.stock.isNotEmpty) {
      chips.add(
        metaChip(Icons.inventory_2_outlined, 'Stoc ${widget.product.stock}'),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget descriptionSection() {
    final text = productDescription;
    final shouldCollapse = text.length > 260;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descriere',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 260),
          crossFadeState: descriptionExpanded || !shouldCollapse
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.55),
          ),
          secondChild: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.55),
          ),
        ),
        if (shouldCollapse) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                descriptionExpanded = !descriptionExpanded;
              });
            },
            icon: Icon(
              descriptionExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            label: Text(
              descriptionExpanded ? 'Arată mai puțin' : 'Citește mai mult',
            ),
          ),
        ],
      ],
    );
  }

  Widget quantitySelector() {
    final stock = stockValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Cantitate',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: quantity > 1
                ? () {
                    setState(() {
                      quantity--;
                    });
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: primaryColor,
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: quantity < stock
                ? () {
                    setState(() {
                      quantity++;
                    });
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget premiumBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total produs',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                priceSection(priceSize: 18, oldPriceSize: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: hasStock ? handleAddToCart : null,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(hasStock ? 'Adaugă x$quantity' : 'Stoc 0'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [''];

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isFavorite),
                  color: isFavorite ? Colors.red : primaryColor,
                ),
              ),
              onPressed: handleToggleFavorite,
            ),
          ),
        ],
      ),
      bottomNavigationBar: premiumBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageGallery(images),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.category,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.product.discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: const Text(
                            'REDUCERE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  priceSection(),
                  const SizedBox(height: 14),
                  productMeta(),
                  const SizedBox(height: 10),
                  Text(
                    hasStock
                        ? 'Stoc disponibil: $stockValue buc.'
                        : 'Stoc indisponibil',
                    style: TextStyle(
                      color: hasStock ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  quantitySelector(),
                  const SizedBox(height: 20),
                  trustBadges(),
                  const SizedBox(height: 28),
                  descriptionSection(),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard_rounded,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Perfect pentru cadouri și surprize memorabile.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
