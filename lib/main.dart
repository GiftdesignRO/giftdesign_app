import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color(0xFFC61B2A);

void main() {
  runApp(const GiftDesignApp());
}

class GiftDesignApp extends StatelessWidget {
  const GiftDesignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiftDesign',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _rotation = Tween<double>(begin: -0.035, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: const Duration(milliseconds: 550),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: RotationTransition(
                  turns: _rotation,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String searchQuery = '';
  String selectedCategory = 'Toate';

  final Map<String, CartItem> cart = {};
  final Set<Product> favorites = {};

  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('http://172.16.255.119:3000/products'));

    if (response.statusCode != 200) {
      throw Exception('Nu am putut încărca produsele din MerchantPro');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((item) => Product.fromJson(item)).toList();
  }

  String cartKey(Product product) => product.sku.isNotEmpty ? product.sku : product.title;

  int get cartItemCount => cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get cartTotal => cart.values.fold<double>(0, (sum, item) => sum + item.total);

  void addToCart(Product product) {
    final key = cartKey(product);
    setState(() {
      if (cart.containsKey(key)) {
        cart[key]!.quantity++;
      } else {
        cart[key] = CartItem(product: product);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.title} adăugat în coș')),
    );
  }

  void increaseQuantity(String key) {
    setState(() => cart[key]?.quantity++);
  }

  void decreaseQuantity(String key) {
    setState(() {
      final item = cart[key];
      if (item == null) return;
      if (item.quantity <= 1) {
        cart.remove(key);
      } else {
        item.quantity--;
      }
    });
  }

  void removeFromCart(String key) {
    setState(() => cart.remove(key));
  }

  void clearCart() {
    setState(() => cart.clear());
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product)) {
        favorites.remove(product);
      } else {
        favorites.add(product);
      }
    });
  }

  List<String> getCategories(List<Product> products) {
    final categories = products
        .map((product) => product.category)
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();

    categories.sort();

    return ['Toate', ...categories];
  }

  List<Product> applyFilters(List<Product> products) {
    final filtered = products.where((product) {
      final matchesSearch = product.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = selectedCategory == 'Toate' || product.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a.dateModified.isNotEmpty ? a.dateModified : a.dateCreated);
      final bDate = DateTime.tryParse(b.dateModified.isNotEmpty ? b.dateModified : b.dateCreated);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(),
      buildCategoriesOnly(),
      buildFavorites(),
      buildCart(),
      buildAccount(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GiftDesign',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorii'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite),
                if (favorites.isNotEmpty)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: badge(favorites.length),
                  ),
              ],
            ),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.isNotEmpty)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: badge(cartItemCount),
                  ),
              ],
            ),
            label: 'Coș',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Cont'),
        ],
      ),
    );
  }

  Widget badge(int value) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
      child: Text(
        value.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildHome() {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Eroare: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];
        final categories = getCategories(products);
        final filteredProducts = applyFilters(products);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchBox(),
              const SizedBox(height: 18),
              promoBanner(),
              const SizedBox(height: 20),
              const SizedBox(height: 12),
              categoryChips(categories),
              const SizedBox(height: 20),
              Text(
                '${filteredProducts.length} produse',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(child: productGrid(filteredProducts)),
            ],
          ),
        );
      },
    );
  }

  Widget buildCategoriesOnly() {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!;
        final categories = getCategories(products);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = category == 'Toate'
                ? products.length
                : products.where((product) => product.category == category).length;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.category, color: primaryColor),
                title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$count produse'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                    selectedIndex = 0;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget searchBox() {
    return Container(
      height: 55,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Caută produse...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget promoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Cadouri personalizate', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Alege un cadou memorabil pentru orice ocazie', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget categoryChips(List<String> categories) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? primaryColor : Colors.grey.shade300),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget productGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Nu am găsit produse'));
    }

    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 365,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final isFavorite = favorites.contains(product);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductPage(
                  product: product,
                  onAddToCart: addToCart,
                  onToggleFavorite: toggleFavorite,
                  isFavorite: isFavorite,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: product.images.first.isEmpty
                          ? Container(
                              height: 145,
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.image)),
                            )
                          : Image.network(
                              product.images.first,
                              height: 145,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: GestureDetector(
                        onTap: () => toggleFavorite(product),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(product.price, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => addToCart(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 36),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Text('Cumpără'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildFavorites() {
    if (favorites.isEmpty) {
      return const Center(child: Text('Nu ai produse favorite'));
    }

    final list = favorites.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final product = list[index];
        return productListTile(product, trailing: IconButton(
          icon: const Icon(Icons.delete, color: primaryColor),
          onPressed: () => toggleFavorite(product),
        ));
      },
    );
  }

  Widget buildAccount() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 18),
        const Icon(Icons.account_circle_outlined, size: 72, color: primaryColor),
        const SizedBox(height: 14),
        const Text(
          'Contul meu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Intră în cont sau creează unul nou pentru a salva comenzile și datele tale.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Creare cont - urmează conectarea cu backend-ul')),
              );
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Creează cont'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Autentificare - urmează conectarea cu backend-ul')),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Autentificare'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCart() {
    if (cart.isEmpty) {
      return const Center(child: Text('Coșul este gol'));
    }

    final items = cart.entries.toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              final key = entry.key;
              final item = entry.value;
              final product = item.product;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: product.images.first.isEmpty
                            ? Container(width: 68, height: 68, color: Colors.grey.shade200, child: const Icon(Icons.image))
                            : Image.network(product.images.first, width: 68, height: 68, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(product.price, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  onPressed: () => decreaseQuantity(key),
                                  icon: const Icon(Icons.remove),
                                  iconSize: 18,
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => increaseQuantity(key),
                                  icon: const Icon(Icons.add),
                                  iconSize: 18,
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => removeFromCart(key),
                                  icon: const Icon(Icons.delete_outline, color: primaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${cartTotal.toStringAsFixed(2)} Lei', style: const TextStyle(fontSize: 20, color: primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          items: cart.values.toList(),
                          total: cartTotal,
                          onOrderDone: clearCart,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  child: const Text('Finalizează comanda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget productListTile(Product product, {Widget? trailing}) {
    return Card(
      child: ListTile(
        leading: product.images.first.isEmpty
            ? const Icon(Icons.image)
            : Image.network(product.images.first, width: 60, height: 60, fit: BoxFit.cover),
        title: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(product.price, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        trailing: trailing,
      ),
    );
  }
}


class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double total;
  final VoidCallback onOrderDone;

  const CheckoutPage({
    super.key,
    required this.items,
    required this.total,
    required this.onOrderDone,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  String? selectedCounty;
  String? selectedCity;
  String deliveryMethod = 'Curier rapid';
  String paymentMethod = 'Ramburs';

  final Map<String, List<String>> romanianCities = const {
    'București': ['Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Sector 5', 'Sector 6'],
    'Alba': ['Alba Iulia', 'Aiud', 'Blaj', 'Sebeș'],
    'Arad': ['Arad', 'Ineu', 'Lipova', 'Nădlac'],
    'Argeș': ['Pitești', 'Câmpulung', 'Curtea de Argeș', 'Mioveni'],
    'Bacău': ['Bacău', 'Onești', 'Moinești', 'Comănești'],
    'Bihor': ['Oradea', 'Salonta', 'Marghita', 'Beiuș'],
    'Brașov': ['Brașov', 'Făgăraș', 'Săcele', 'Codlea'],
    'Cluj': ['Cluj-Napoca', 'Turda', 'Dej', 'Câmpia Turzii'],
    'Constanța': ['Constanța', 'Mangalia', 'Medgidia', 'Năvodari'],
    'Dolj': ['Craiova', 'Băilești', 'Calafat', 'Filiași'],
    'Galați': ['Galați', 'Tecuci', 'Târgu Bujor'],
    'Iași': ['Iași', 'Pașcani', 'Hârlău', 'Târgu Frumos'],
    'Ilfov': ['Voluntari', 'Otopeni', 'Popești-Leordeni', 'Buftea', 'Chiajna'],
    'Prahova': ['Ploiești', 'Câmpina', 'Sinaia', 'Bușteni'],
    'Timiș': ['Timișoara', 'Lugoj', 'Sânnicolau Mare', 'Jimbolia'],
  };

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counties = romanianCities.keys.toList()..sort();
    final cities = selectedCounty == null ? <String>[] : romanianCities[selectedCounty] ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Date livrare', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextFormField(
              controller: nameController,
              decoration: fieldDecoration('Nume și prenume'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Completează numele' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration('Telefon'),
              validator: (value) => value == null || value.trim().length < 8 ? 'Completează telefonul' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration('Email'),
              validator: (value) => value == null || !value.contains('@') ? 'Email invalid' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCounty,
              decoration: fieldDecoration('Județ'),
              items: counties.map((county) => DropdownMenuItem(value: county, child: Text(county))).toList(),
              onChanged: (value) => setState(() { selectedCounty = value; selectedCity = null; }),
              validator: (value) => value == null ? 'Alege județul' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: fieldDecoration('Oraș / Localitate'),
              items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
              onChanged: selectedCounty == null ? null : (value) => setState(() => selectedCity = value),
              validator: (value) => value == null ? 'Alege orașul' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              maxLines: 2,
              decoration: fieldDecoration('Adresă completă'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Completează adresa' : null,
            ),
            const SizedBox(height: 20),
            const Text('Livrare', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              value: 'Curier rapid',
              groupValue: deliveryMethod,
              activeColor: primaryColor,
              title: const Text('Curier rapid'),
              onChanged: (value) => setState(() => deliveryMethod = value!),
            ),
            RadioListTile<String>(
              value: 'Ridicare personală',
              groupValue: deliveryMethod,
              activeColor: primaryColor,
              title: const Text('Ridicare personală'),
              onChanged: (value) => setState(() => deliveryMethod = value!),
            ),
            const Text('Plată', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              value: 'Ramburs',
              groupValue: paymentMethod,
              activeColor: primaryColor,
              title: const Text('Ramburs'),
              onChanged: (value) => setState(() => paymentMethod = value!),
            ),
            RadioListTile<String>(
              value: 'Card online',
              groupValue: paymentMethod,
              activeColor: primaryColor,
              title: const Text('Card online'),
              onChanged: (value) => setState(() => paymentMethod = value!),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sumar comandă', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...widget.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.quantity} x ${item.product.title}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('${item.total.toStringAsFixed(2)} Lei'),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.total.toStringAsFixed(2)} Lei', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onOrderDone();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Comandă trimisă'),
                      content: const Text('Comanda a fost înregistrată. Urmează integrarea cu backend-ul pentru trimitere reală.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Trimite comanda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
