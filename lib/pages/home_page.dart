import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'checkout_page.dart';
import 'product_page.dart';
import 'admin_orders_page.dart';
import 'order_tracking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String searchQuery = '';
  String selectedCategory = 'Toate';
  String selectedSort = 'noi';
  bool showMainCategoryProducts = false;
  String accountMode = 'menu';
  String? loggedUserName;
  String? loggedUserEmail;
  bool accountLoading = false;
  bool darkMode = false;
  int analyticsProductViews = 0;
  int analyticsAddToCart = 0;
  int analyticsSearches = 0;
  bool cartBounce = false;

  final accountNameController = TextEditingController();
  final accountEmailController = TextEditingController();
  final accountPasswordController = TextEditingController();
  final accountConfirmPasswordController = TextEditingController();
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final Map<String, CartItem> cart = {};
  final Set<Product> favorites = {};
  final Set<String> favoriteKeys = {};
  final List<Product> recentlyViewed = [];

  static const List<CategoryGroup> siteCategories = [
    CategoryGroup(title: 'Carduri Cadou', icon: Icons.card_giftcard, subcategories: []),
    CategoryGroup(title: 'Home & deco', icon: Icons.chair_outlined, subcategories: [
      'Lămpi solare', 'Seturi mobilă grădină', 'Mese', 'Coșuri pentru rufe și ligheane', 'Suporturi și accesorii de baie', 'Oglinzi decorative', 'Ceasuri decorative', 'Birouri', 'Scaune birou', 'Plante artificiale', 'Umbrele și pavilioane grădină', 'Veioze și lămpi', 'Scaune', 'Rafturi', 'Cuiere', 'Veselă pentru masă și tacâmuri', 'Covorașe intrare', 'Coșuri picnic', 'Mobilier gradină', 'Accesorii pentru grădină', 'Lanterne', 'Balansoare și hamace', 'Uscătoare rufe', 'Mobilă living și biblioteci', 'Dulapuri pantofi', 'Mese grădină', 'Măsuțe de toaletă', 'Comode', 'Șifoniere și dulapuri', 'Oglinzi și mobilier baie', 'Cutii alimentare', 'Seturi mobilă bucătărie', 'Prosoape', 'Aranjamente florale', 'Albume foto', 'Vaze și boluri decorative', 'Perne decorative', 'Odorizante cameră', 'Fețe de masă', 'Suporturi lumânări', 'Bucatărie și servire', 'Accesorii grătar', 'Accesorii decorative', 'Corpuri de iluminat', 'Cutii depozitare', 'Ghivece și suporturi', 'Etajere', 'Lumânări și candele', 'Rame foto', 'Tăvi servire', 'Umidificatoare', 'Veselă desert'
    ]),
    CategoryGroup(title: 'Jucării, Copii & Bebe', icon: Icons.toys_outlined, subcategories: ['Trambuline', 'Căsuțe și corturi copii', 'Prosoape și halate de baie copii', 'Accesorii transport copii', 'Fuste fete', 'Rucsacuri și genți copii', 'Jucării pentru plajă și nisip', 'Jucării pentru dentiție', 'Jucării zornăitoare', 'Jucării de tras/împins', 'Jucării interactive bebeluși', 'Jucării de pluș', 'Jucării interactive', 'Jucării figurine', 'Jucării de exterior', 'Jocuri de îndemânare', 'Păpuși', 'Articole hrănire bebeluși', 'Suzete și accesorii', 'Mașinuțe', 'Motociclete de jucărie', 'Puzzle', 'Piscine copii', 'Seturi arheologice', 'Seturi de artizanat', 'Seturi de construcție', 'Seturi pictură și desen']),
    CategoryGroup(title: 'Party', icon: Icons.celebration_outlined, subcategories: ['Lumânări', 'Accesorii party', 'Magic POP-UPS', 'Veselă party', 'Baloane', 'Artificii și confetti', 'Pahare party', 'Felicitări', 'Șervețele party']),
    CategoryGroup(title: 'Fashion', icon: Icons.checkroom_outlined, subcategories: ['Ochelari de soare bărbați', 'Ochelari de soare damă', 'Ochelari de soare copii', 'Șlapi, papuci și saboți damă', 'Șlapi și papuci bărbați', 'Papuci și șlapi copii', 'Sandale copii', 'Pălării damă', 'Șosete damă', 'Șosete bărbați', 'Rucsacuri damă', 'Genți damă', 'Genți laptop', 'Huse tablete', 'Portofele damă', 'Umbrele bărbați', 'Umbrele femei', 'Ceasuri copii', 'Rochii fete', 'Bijuterii copii', 'Eșarfe damă', 'Cutii bijuterii', 'Bijuterii damă', 'Accesorii plajă', 'Accesorii păr', 'Brelocuri', 'Măști și costume carnaval']),
    CategoryGroup(title: 'Sport', icon: Icons.sports_soccer_outlined, subcategories: ['Haltere și gantere', 'Extensoare și benzi elastice', 'Mingi fitness', 'Fitness și nutriție', 'Scaune, mese și umbrele camping', 'Food', 'Rucsacuri', 'Genți termo-izolante', 'Accesorii fitness', 'Saltele', 'Trolere', 'Corzi sărituri', 'Bord-uri de darts', 'Borsete sport', 'Genți voiaj', 'Bidoane și shakere', 'Suport telefon', 'Mănuși Sport', 'Coșuri și panouri baschet', 'Accesorii camping și drumeții', 'Genți sport, fitness', 'Mese biliard', 'Mese foosball', 'Steppere']),
    CategoryGroup(title: 'Petshop', icon: Icons.pets_outlined, subcategories: ['Cuști, cotețe, tarcuri și colivii', 'Ansambluri de joacă animale', 'Culcușuri, perne si saltele pentru animale', 'Zgărzi, lese și hamuri', 'Jucării animale', 'Litiere', 'Perii, trimmere și clești animale', 'Castroane și adăpători animale', 'Genti si articole transport', 'Accesorii litiere', 'Echipament dresaj']),
    CategoryGroup(title: 'Camera copilului', icon: Icons.child_care_outlined, subcategories: ['Mobilier', 'Perne', 'Păturici bebe', 'Pușculițe', 'Decorațiuni', 'Covorașe copii', 'Ceasuri', 'Lămpi de veghe']),
    CategoryGroup(title: 'Rechizite', icon: Icons.edit_note_outlined, subcategories: ['Penare', 'Ghiozdane și genți', 'Seturi rechizite', 'Carnețele', 'Agende și calendare', 'Corectoare și radiere', 'Creioane', 'Semne de carte', 'Stickere', 'Cretă și table școlare', 'Pixuri', 'Creioane colorate și carioci', 'Acuarele, pensule si blocuri de desen', 'Hărți de perete și globuri pământești', 'Suport carte și tabletă', 'Markere', 'Cuburi hârtie și note adezive', 'Mape, serviete și clipboarduri']),
    CategoryGroup(title: 'Îngrijire personală', icon: Icons.spa_outlined, subcategories: ['Oglinzi cosmetice', 'Portfarduri și genți cosmetice', 'Tatuaje temporare', 'Suporturi ortopedice si orteze', 'Îngrijire corp', 'Accesorii machiaj', 'Măști pentru ten și gomaje', 'Aparate de masaj', 'Aplicatoare și pensule machiaj', 'Seturi de relaxare']),
    CategoryGroup(title: 'Ambalare cadou', icon: Icons.redeem_outlined, subcategories: ['Hârtie ambalat', 'Cutii băuturi', 'Steluțe adezive', 'Accesorii', 'Cutii de cadou', 'Pungi de cadou', 'Lichidare de stoc']),
  ];

  late Future<List<Product>> productsFuture;
  late Future<List<CategoryData>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
    categoriesFuture = fetchCategories();
    loadSavedUser();
    loadSavedFavorites();
    loadPhase3Settings();
  }

  @override
  void dispose() {
    accountNameController.dispose();
    accountEmailController.dispose();
    accountPasswordController.dispose();
    accountConfirmPasswordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.dispose();
  }

  Future<List<Product>> fetchProducts() => ApiService.fetchProducts();

  Future<List<CategoryData>> fetchCategories() => ApiService.fetchCategories();

  Future<void> loadSavedUser() async {
  final savedUser = await SessionService.loadUser();
  final savedName = savedUser['name'];
  final savedEmail = savedUser['email'];

  if (!mounted) return;

  if (savedEmail != null) {
    setState(() {
      loggedUserName = savedName;
      loggedUserEmail = savedEmail;
      accountMode = 'profile';
    });
  }
}

Future<void> saveUserSession(Map<String, dynamic> user) async {
  await SessionService.saveUser(user);

  if (!mounted) return;

  setState(() {
    loggedUserName = user['name'];
    loggedUserEmail = user['email'];
    accountMode = 'profile';
  });
}

Future<void> logoutAccount() async {
  await SessionService.clear();

  setState(() {
    loggedUserName = null;
    loggedUserEmail = null;
    accountMode = 'menu';
  });
}

  Future<void> loadSavedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('favorite_product_keys') ?? [];

    favoriteKeys
      ..clear()
      ..addAll(savedKeys);

    try {
      final products = await productsFuture;
      if (!mounted) return;

      setState(() {
        favorites
          ..clear()
          ..addAll(products.where((product) => favoriteKeys.contains(cartKey(product))));
      });
    } catch (_) {
      // Favorites will be restored on the next successful products load.
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_product_keys', favoriteKeys.toList());
  }

  Future<void> loadPhase3Settings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;
      analyticsProductViews = prefs.getInt('analytics_product_views') ?? 0;
      analyticsAddToCart = prefs.getInt('analytics_add_to_cart') ?? 0;
      analyticsSearches = prefs.getInt('analytics_searches') ?? 0;
    });
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    setState(() {
      darkMode = value;
    });
  }

  Future<void> saveAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('analytics_product_views', analyticsProductViews);
    await prefs.setInt('analytics_add_to_cart', analyticsAddToCart);
    await prefs.setInt('analytics_searches', analyticsSearches);
  }

  void trackProductView() {
    analyticsProductViews++;
    saveAnalytics();
  }

  void trackAddToCart() {
    analyticsAddToCart++;
    saveAnalytics();
  }

  void trackSearch() {
    analyticsSearches++;
    saveAnalytics();
  }

  Color get appBackgroundColor => darkMode ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
  Color get appCardColor => darkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get appTextColor => darkMode ? Colors.white : Colors.black;
  Color get appMutedTextColor => darkMode ? Colors.grey.shade400 : Colors.grey.shade700;

  void addRecentlyViewed(Product product) {
    setState(() {
      recentlyViewed.removeWhere((item) => cartKey(item) == cartKey(product));
      recentlyViewed.insert(0, product);

      if (recentlyViewed.length > 10) {
        recentlyViewed.removeRange(10, recentlyViewed.length);
      }
    });
  }

  String cartKey(Product product) => product.sku.isNotEmpty ? product.sku : product.title;

  int get cartItemCount => cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get cartTotal => cart.values.fold<double>(0, (sum, item) => sum + item.total);

  void addToCart(Product product) {
    trackAddToCart();

    final key = cartKey(product);

    setState(() {
      if (cart.containsKey(key)) {
        cart[key]!.quantity++;
      } else {
        cart[key] = CartItem(product: product);
      }

      cartBounce = true;
    });

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;

      setState(() {
        cartBounce = false;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} adăugat în coș'),
        duration: const Duration(seconds: 2),
        action: selectedIndex == 3
            ? null
            : SnackBarAction(
                label: 'Vezi coșul',
                onPressed: () {
                  setState(() {
                    selectedIndex = 3;
                  });
                },
              ),
      ),
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
    final key = cartKey(product);

    setState(() {
      if (favoriteKeys.contains(key)) {
        favoriteKeys.remove(key);
        favorites.removeWhere((item) => cartKey(item) == key);
      } else {
        favoriteKeys.add(key);
        favorites.add(product);
      }
    });

    saveFavorites();
  }

  String normalizeCategory(String value) => value.trim().toLowerCase();

  List<String> getCategories(List<Product> products) {
    // În zona de sub header afișăm doar categoriile principale de pe site,
    // nu subcategoriile venite din MerchantPro.
    return ['Toate', ...siteCategories.map((group) => group.title)];
  }

  bool matchesSelectedCategory(Product product) {
    if (selectedCategory == 'Toate') return true;

    final productCategory = normalizeCategory(product.category);
    final selected = normalizeCategory(selectedCategory);
    if (productCategory == selected) return true;

    final selectedGroups = siteCategories.where((group) => normalizeCategory(group.title) == selected).toList();
    if (selectedGroups.isEmpty) return false;

    return selectedGroups.first.subcategories.map(normalizeCategory).contains(productCategory);
  }

  int countForCategory(List<Product> products, String category) {
    if (category == 'Toate') return products.length;
    final normalized = normalizeCategory(category);
    final groups = siteCategories.where((group) => normalizeCategory(group.title) == normalized).toList();

    if (groups.isNotEmpty) {
      final accepted = {normalizeCategory(groups.first.title), ...groups.first.subcategories.map(normalizeCategory)};
      return products.where((product) => accepted.contains(normalizeCategory(product.category))).length;
    }

    return products.where((product) => normalizeCategory(product.category) == normalized).length;
  }


  CategoryData? merchantCategoryFor(List<CategoryData> categories, String category) {
    final normalized = normalizeCategory(category);

    for (final item in categories) {
      if (normalizeCategory(item.name) == normalized) return item;
    }

    return null;
  }

  String merchantImageForCategory(List<CategoryData> categories, List<Product> products, String category) {
    final merchantCategory = merchantCategoryFor(categories, category);
    final parentGroup = parentCategoryFor(category);

    if (merchantCategory != null) {
      if (parentGroup != null) {
        if (merchantCategory.imageSubcategory.isNotEmpty) return merchantCategory.imageSubcategory;
        if (merchantCategory.menuImage.isNotEmpty) return merchantCategory.menuImage;
        if (merchantCategory.menuIcon.isNotEmpty) return merchantCategory.menuIcon;
      } else {
        if (merchantCategory.menuImage.isNotEmpty) return merchantCategory.menuImage;
        if (merchantCategory.imageSubcategory.isNotEmpty) return merchantCategory.imageSubcategory;
        if (merchantCategory.menuIcon.isNotEmpty) return merchantCategory.menuIcon;
      }
    }

    // Fallback: if MerchantPro has no dedicated image for this category,
    // use the first product image so the UI never remains blank.
    Iterable<Product> candidates;

    if (category == 'Toate') {
      candidates = products;
    } else {
      final normalized = normalizeCategory(category);
      final groups = siteCategories.where((group) => normalizeCategory(group.title) == normalized).toList();

      if (groups.isNotEmpty) {
        final accepted = {normalizeCategory(groups.first.title), ...groups.first.subcategories.map(normalizeCategory)};
        candidates = products.where((product) => accepted.contains(normalizeCategory(product.category)));
      } else {
        candidates = products.where((product) => normalizeCategory(product.category) == normalized);
      }
    }

    for (final product in candidates) {
      if (product.images.isNotEmpty && product.images.first.trim().isNotEmpty) {
        return product.images.first;
      }
    }

    return '';
  }


  Widget imageThumb(String imageUrl, {IconData fallbackIcon = Icons.category_outlined, double height = 84, double width = double.infinity, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: radius,
      child: imageUrl.isEmpty
          ? Container(
              height: height,
              width: width,
              color: primaryColor.withOpacity(0.08),
              child: Icon(fallbackIcon, color: primaryColor, size: 30),
            )
          : CachedNetworkImage(
              imageUrl: imageUrl,
              height: height,
              width: width,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, __) => Container(
                height: height,
                width: width,
                color: Colors.grey.shade200,
              ),
              errorWidget: (_, __, ___) => Container(
                height: height,
                width: width,
                color: primaryColor.withOpacity(0.08),
                child: Icon(fallbackIcon, color: primaryColor, size: 30),
              ),
            ),
    );
  }

  CategoryGroup? mainCategoryFor(String category) {
    final normalized = normalizeCategory(category);
    for (final group in siteCategories) {
      if (normalizeCategory(group.title) == normalized) return group;
    }
    return null;
  }

  CategoryGroup? parentCategoryFor(String category) {
    final normalized = normalizeCategory(category);
    for (final group in siteCategories) {
      if (group.subcategories.map(normalizeCategory).contains(normalized)) {
        return group;
      }
    }
    return null;
  }

  void goBackInCategories() {
    final parentGroup = parentCategoryFor(selectedCategory);

    setState(() {
      if (parentGroup != null) {
        selectedCategory = parentGroup.title;
        showMainCategoryProducts = false;
        return;
      }

      selectedCategory = 'Toate';
      showMainCategoryProducts = false;
    });
  }

  String categoryBreadcrumb() {
    if (selectedCategory == 'Toate') return 'Home';

    final parentGroup = parentCategoryFor(selectedCategory);
    if (parentGroup != null) {
      return 'Home / ${parentGroup.title} / $selectedCategory';
    }

    if (showMainCategoryProducts) {
      return 'Home / $selectedCategory / Toate produsele';
    }

    return 'Home / $selectedCategory';
  }

  List<Product> applyFilters(List<Product> products) {
    final query = searchQuery.toLowerCase().trim();

    final filtered = products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);

      return matchesSearch && matchesSelectedCategory(product);
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a.dateModified.isNotEmpty ? a.dateModified : a.dateCreated);
      final bDate = DateTime.tryParse(b.dateModified.isNotEmpty ? b.dateModified : b.dateCreated);

      switch (selectedSort) {
        case 'pret_crescator':
          return priceValue(a).compareTo(priceValue(b));
        case 'pret_descrescator':
          return priceValue(b).compareTo(priceValue(a));
        case 'populare':
          final aScore = popularityScore(a);
          final bScore = popularityScore(b);
          if (aScore != bScore) return bScore.compareTo(aScore);
          return a.title.compareTo(b.title);
        case 'noi':
        default:
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
      }
    });

    return filtered;
  }

  double priceValue(Product product) {
    final cleaned = product.price
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  int popularityScore(Product product) {
    final key = cartKey(product);
    var score = 0;

    if (favoriteKeys.contains(key)) score += 5;
    if (cart.containsKey(key)) score += cart[key]!.quantity * 3;
    score += recentlyViewed.where((item) => cartKey(item) == key).length;

    return score;
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
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appCardColor,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            setState(() {
              selectedCategory = 'Toate';
              showMainCategoryProducts = false;
              searchQuery = '';
              selectedIndex = 0;
            });
          },
          child: Image.asset(
            'assets/images/logo.png',
            height: 38,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: appCardColor,
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
            icon: AnimatedScale(
              scale: cartBounce ? 1.25 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.elasticOut,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedRotation(
                    turns: cartBounce ? 0.035 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: AnimatedScale(
                        scale: cartBounce ? 1.18 : 1,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.elasticOut,
                        child: badge(cartItemCount),
                      ),
                    ),
                ],
              ),
            ),
            label: 'Coș',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.account_circle),

                if (loggedUserEmail != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: loggedUserName != null &&
                    loggedUserName!.isNotEmpty
                ? loggedUserName!
                : 'Cont',
          ),
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


  Widget buildHomeSkeleton() {
    Widget skeletonBox({
      required double height,
      double width = double.infinity,
      double radius = 16,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    Widget productSkeletonCard() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            skeletonBox(height: 155, radius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    skeletonBox(height: 12, width: 82, radius: 8),
                    const SizedBox(height: 9),
                    skeletonBox(height: 15, width: double.infinity, radius: 8),
                    const SizedBox(height: 7),
                    skeletonBox(height: 15, width: 120, radius: 8),
                    const Spacer(),
                    skeletonBox(height: 22, width: 96, radius: 8),
                    const SizedBox(height: 10),
                    skeletonBox(height: 40, radius: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          skeletonBox(height: 55, radius: 14),
          const SizedBox(height: 18),
          skeletonBox(height: 112, radius: 22),
          const SizedBox(height: 22),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) =>
                  skeletonBox(height: 116, width: 118, radius: 18),
            ),
          ),
          const SizedBox(height: 24),
          skeletonBox(height: 28, width: 160, radius: 8),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 365,
            ),
            itemBuilder: (_, __) => productSkeletonCard(),
          ),
        ],
      ),
    );
  }

  Widget buildHome() {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildHomeSkeleton();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Eroare: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        return FutureBuilder<List<CategoryData>>(
          future: categoriesFuture,
          builder: (context, categorySnapshot) {
            final merchantCategories = categorySnapshot.data ?? [];
            final categories = getCategories(products);
            final filteredProducts = applyFilters(products);
        final selectedMainGroup = mainCategoryFor(selectedCategory);
        final selectedParentGroup = parentCategoryFor(selectedCategory);
        final showCategoryNavigation = selectedCategory != 'Toate';
        final dynamicCategories = products.map((product) => product.category.trim()).where((category) => category.isNotEmpty).toSet();
        final visibleSubcategories = selectedMainGroup == null
            ? <String>[]
            : selectedMainGroup.subcategories.where((subcategory) => dynamicCategories.contains(subcategory)).toList();
        final showSubcategories = searchQuery.trim().isEmpty &&
            selectedMainGroup != null &&
            selectedCategory == selectedMainGroup.title &&
            !showMainCategoryProducts &&
            visibleSubcategories.isNotEmpty;

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: StickySearchHeaderDelegate(
                height: 79,
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: searchBox(),
                ),
              ),
            ),
            if (showCategoryNavigation)
              SliverPersistentHeader(
                pinned: true,
                delegate: StickySearchHeaderDelegate(
                  height: 92,
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: categoryNavigationBar(
                      title: selectedParentGroup != null
                          ? selectedParentGroup.title
                          : selectedCategory,
                      breadcrumb: categoryBreadcrumb(),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    promoBanner(),
                    const SizedBox(height: 20),
                    categoryChips(categories, products, merchantCategories),
                    const SizedBox(height: 14),
                    sortBar(),
                    const SizedBox(height: 20),
                    recentlyViewedSection(),
                    if (recentlyViewed.isNotEmpty) const SizedBox(height: 22),
                    Text(
                      showSubcategories
                          ? 'Subcategorii ${selectedMainGroup.title}'
                          : '${filteredProducts.length} produse',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (showSubcategories) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Alege o subcategorie pentru a vedea produsele.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (showSubcategories)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 210,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return mainCategoryAllProductsCard(selectedMainGroup.title, countForCategory(products, selectedMainGroup.title), merchantImageForCategory(merchantCategories, products, selectedMainGroup.title));
                      }
                      final subcategory = visibleSubcategories[index - 1];
                      return subcategoryCard(subcategory, countForCategory(products, subcategory), merchantImageForCategory(merchantCategories, products, subcategory));
                    },
                    childCount: visibleSubcategories.length + 1,
                  ),
                ),
              )
            else if (filteredProducts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Nu am găsit produse')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 365,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => productCard(filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                ),
              ),
          ],
        );
          },
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

        return FutureBuilder<List<CategoryData>>(
          future: categoriesFuture,
          builder: (context, categorySnapshot) {
            final merchantCategories = categorySnapshot.data ?? [];
            final dynamicCategories = products.map((product) => product.category.trim()).where((category) => category.isNotEmpty).toSet();
        final mappedValues = <String>{for (final group in siteCategories) ...[group.title, ...group.subcategories]};
        final otherCategories = dynamicCategories.where((category) => !mappedValues.contains(category)).toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageThumb(merchantImageForCategory(merchantCategories, products, 'Toate'), fallbackIcon: Icons.grid_view_rounded, height: 46, width: 46)),
                title: const Text('Toate produsele', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${products.length} produse'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => setState(() { selectedCategory = 'Toate'; showMainCategoryProducts = false; selectedIndex = 0; }),
              ),
            ),
            const SizedBox(height: 8),
            ...siteCategories.map((group) {
              final groupCount = countForCategory(products, group.title);
              final visibleSubcategories = group.subcategories.where((subcategory) => dynamicCategories.contains(subcategory)).toList();

              if (visibleSubcategories.isEmpty) {
                return Card(
                  child: ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageThumb(merchantImageForCategory(merchantCategories, products, group.title), fallbackIcon: group.icon, height: 46, width: 46)),
                    title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$groupCount produse'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => setState(() { selectedCategory = group.title; showMainCategoryProducts = false; selectedIndex = 0; }),
                  ),
                );
              }

              return Card(
                child: ExpansionTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageThumb(merchantImageForCategory(merchantCategories, products, group.title), fallbackIcon: group.icon, height: 46, width: 46)),
                  title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$groupCount produse'),
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: Text('Toate din ${group.title}'),
                      trailing: Text('$groupCount'),
                      onTap: () => setState(() { selectedCategory = group.title; showMainCategoryProducts = false; selectedIndex = 0; }),
                    ),
                    ...visibleSubcategories.map((subcategory) {
                      final count = countForCategory(products, subcategory);
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                        title: Text(subcategory),
                        trailing: Text('$count'),
                        onTap: () => setState(() { selectedCategory = subcategory; showMainCategoryProducts = false; selectedIndex = 0; }),
                      );
                    }),
                  ],
                ),
              );
            }),
            if (otherCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.more_horiz, color: primaryColor),
                  title: const Text('Alte categorii', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${otherCategories.length} categorii'),
                  children: otherCategories.map((category) => ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    title: Text(category),
                    trailing: Text('${countForCategory(products, category)}'),
                    onTap: () => setState(() { selectedCategory = category; showMainCategoryProducts = false; selectedIndex = 0; }),
                  )).toList(),
                ),
              ),
            ],
          ],
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
          if (value.trim().isNotEmpty) {
            trackSearch();
          }

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

  Widget categoryNavigationBar({required String title, required String breadcrumb}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: goBackInCategories,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breadcrumb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget sortBar() {
    final options = [
      {'key': 'noi', 'label': 'Noi'},
      {'key': 'pret_crescator', 'label': 'Preț ↑'},
      {'key': 'pret_descrescator', 'label': 'Preț ↓'},
      {'key': 'populare', 'label': 'Populare'},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = selectedSort == option['key'];

          return ChoiceChip(
            selected: selected,
            label: Text(option['label']!),
            selectedColor: primaryColor.withOpacity(0.12),
            checkmarkColor: primaryColor,
            labelStyle: TextStyle(
              color: selected ? primaryColor : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? primaryColor : Colors.grey.shade300,
            ),
            onSelected: (_) {
              setState(() {
                selectedSort = option['key']!;
              });
            },
          );
        },
      ),
    );
  }

  Widget recentlyViewedSection() {
    if (recentlyViewed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Văzute recent',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentlyViewed.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = recentlyViewed[index];
              final image = product.images.isNotEmpty ? product.images.first : '';

              return GestureDetector(
                onTap: () => openProduct(product),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: image.isEmpty
                            ? Container(
                                width: 72,
                                height: 88,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_outlined),
                              )
                            : CachedNetworkImage(
                                imageUrl: image,
                                width: 72,
                                height: 88,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 250),
                                placeholder: (_, __) => Container(
                                  width: 72,
                                  height: 88,
                                  color: Colors.grey.shade200,
                                ),
                                errorWidget: (_, __, ___) => const Icon(Icons.image_outlined),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            productPriceBlock(
                              product,
                              priceSize: 14,
                              oldPriceSize: 11,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vezi produsul',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
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
          ),
        ),
      ],
    );
  }

  Widget categoryChips(List<String> categories, List<Product> products, List<CategoryData> merchantCategories) {
    final visibleCategories = categories.where((category) => category != 'Toate').toList();

    return SizedBox(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCategories.length,
        itemBuilder: (context, index) {
          final category = visibleCategories[index];
          final selected = selectedCategory == category;
          final image = merchantImageForCategory(merchantCategories, products, category);
          final group = mainCategoryFor(category);
          final icon = group?.icon ?? Icons.category_outlined;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                showMainCategoryProducts = false;
              });
            },
            child: Container(
              width: 118,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? primaryColor : Colors.grey.shade200, width: selected ? 2 : 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      imageThumb(
                        image,
                        fallbackIcon: icon,
                        height: 68,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      ),
                      if (selected)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 9, 0),
                    child: Text(
                      category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? primaryColor : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget mainCategoryAllProductsCard(String category, int count, String imageUrl) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          showMainCategoryProducts = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isEmpty
                ? Container(color: primaryColor, child: const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 42))
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: primaryColor, child: const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 42)),
                  ),
            Container(color: Colors.black.withOpacity(0.35)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.grid_view_rounded, color: primaryColor),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toate din $category', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$count produse', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget subcategoryCard(String subcategory, int count, String imageUrl) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = subcategory;
          showMainCategoryProducts = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                imageThumb(
                  imageUrl,
                  height: 104,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 18),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subcategory, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$count produse', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openProduct(Product product) {
    trackProductView();
    addRecentlyViewed(product);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPage(
          product: product,
          onAddToCart: addToCart,
          onToggleFavorite: toggleFavorite,
          isFavorite: favorites.contains(product),
        ),
      ),
    );
  }



  Widget productPriceBlock(
    Product product, {
    double priceSize = 18,
    double oldPriceSize = 12,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    final hasDiscount =
        product.oldPrice.isNotEmpty && product.discountPercent > 0;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (hasDiscount) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  product.oldPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: oldPriceSize,
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
        ],
        Text(
          product.price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasDiscount ? Colors.red : primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: priceSize,
          ),
        ),
      ],
    );
  }

  Widget productCard(Product product) {
    final isFavorite = favorites.contains(product);
    final image = product.images.isNotEmpty ? product.images.first : '';
    final parsedDate = DateTime.tryParse(product.dateCreated);
    final isNew = parsedDate != null && DateTime.now().difference(parsedDate).inDays <= 30;

    return GestureDetector(
      onTap: () => openProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                image.isEmpty
                    ? Container(
                        height: 155,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image_outlined)),
                      )
                    : Hero(
                        tag: product.sku.isNotEmpty
                            ? product.sku
                            : product.title,
                        child: CachedNetworkImage(
                          imageUrl: image,
                          height: 155,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 350),
                          placeholder: (_, __) => Container(
                            height: 155,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 155,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                      ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.transparent,
                          Colors.black.withOpacity(0.16),
                        ],
                      ),
                    ),
                  ),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else if (isNew)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'NOU',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: () => toggleFavorite(product),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: primaryColor,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.2),
                    ),
                    const Spacer(),
                    productPriceBlock(product),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 17),
                        label: const Text('Adaugă', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      itemBuilder: (context, index) => productCard(products[index]),
    );
  }


  Widget buildFavorites() {
    if (favorites.isEmpty) {
      return const Center(
        child: Text('Nu ai produse favorite'),
      );
    }

    final list = favorites.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final product = list[index];
        final image =
            product.images.isNotEmpty ? product.images.first : '';

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openProduct(product),
          child: Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image.isEmpty
                        ? Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image),
                          )
                        : Image.network(
                            image,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Expanded(
                              child: Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        productPriceBlock(product),

                        const SizedBox(height: 12),

                        Row(
                          children: [

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  addToCart(product);
                                },

                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 18,
                                ),

                                label: const Text('Adaugă'),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      primaryColor,
                                  foregroundColor:
                                      Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    toggleFavorite(product),

                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  InputDecoration accountFieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  Widget buildAccount() {
    if (accountMode == 'register') {
      return buildRegisterForm();
    }

    if (accountMode == 'login') {
      return buildLoginForm();
    }

    if (loggedUserEmail != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 30),
          const Icon(
            Icons.account_circle,
            size: 90,
            color: primaryColor,
          ),
          const SizedBox(height: 18),
          Text(
            loggedUserName ?? 'Client GiftDesign',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loggedUserEmail ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),

          profileQuickActions(),

          const SizedBox(height: 16),

          analyticsDashboard(),

          const SizedBox(height: 16),

SizedBox(
  height: 52,
  child: ElevatedButton.icon(
    onPressed: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AdminOrdersPage(),
        ),
      );
    },

    icon: const Icon(
      Icons.admin_panel_settings,
    ),

    label: const Text(
      'Admin comenzi',
    ),

    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),

      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: logoutAccount,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
              setState(() {
                accountMode = 'register';
              });
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
              setState(() {
                accountMode = 'login';
              });
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


  Widget profileQuickActions() {
    return Column(
      children: [
        SwitchListTile(
          value: darkMode,
          activeColor: primaryColor,
          title: const Text(
            'Dark mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Comută aplicația în modul întunecat'),
          secondary: const Icon(Icons.dark_mode_outlined, color: primaryColor),
          onChanged: saveDarkMode,
        ),
        const SizedBox(height: 12),
        Card(
          color: appCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderTrackingPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: primaryColor, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order tracking',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Urmărește comanda, statusul și AWB-ul.',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget analyticsDashboard() {
    return Card(
      color: appCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: analyticsTile(
                    icon: Icons.visibility_outlined,
                    label: 'Vizualizări',
                    value: analyticsProductViews.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: analyticsTile(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Add to cart',
                    value: analyticsAddToCart.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: analyticsTile(
                    icon: Icons.search,
                    label: 'Căutări',
                    value: analyticsSearches.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget analyticsTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: appMutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget buildRegisterForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  accountMode = 'menu';
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'Creează cont',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: accountNameController,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration('Nume și prenume', Icons.person_outline),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration('Parolă', Icons.lock_outline),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountConfirmPasswordController,
          obscureText: true,
          decoration: accountFieldDecoration('Confirmă parola', Icons.lock_reset),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
  setState(() {
    accountLoading = true;
  });

  try {
    final response = await ApiService.register(
      name: accountNameController.text,
      email: accountEmailController.text,
      password: accountPasswordController.text,
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveUserSession(decoded['user']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cont creat cu succes'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eroare server'),
      ),
    );
  }

  setState(() {
    accountLoading = false;
  });
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
        const SizedBox(height: 14),
        TextButton(
          onPressed: () {
            setState(() {
              accountMode = 'login';
            });
          },
          child: const Text('Ai deja cont? Autentifică-te'),
        ),
      ],
    );
  }

  Widget buildLoginForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  accountMode = 'menu';
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'Autentificare',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: loginPasswordController,
          obscureText: true,
          decoration: accountFieldDecoration('Parolă', Icons.lock_outline),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
  setState(() {
    accountLoading = true;
  });

  try {
    final response = await ApiService.login(
      email: loginEmailController.text,
      password: loginPasswordController.text,
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveUserSession(decoded['user']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login reușit'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decoded['error'] ?? 'Login eșuat',
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eroare server'),
      ),
    );
  }

  setState(() {
    accountLoading = false;
  });
},
            icon: const Icon(Icons.login),
            label: const Text('Autentificare'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () {
            setState(() {
              accountMode = 'register';
            });
          },
          child: const Text('Nu ai cont? Creează unul'),
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

              final image = product.images.isNotEmpty ? product.images.first : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => openProduct(product),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isEmpty
                              ? Container(width: 68, height: 68, color: Colors.grey.shade200, child: const Icon(Icons.image))
                              : Image.network(image, width: 68, height: 68, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
                                ],
                              ),
                              const SizedBox(height: 6),
                              productPriceBlock(
                                product,
                                priceSize: 15,
                                oldPriceSize: 11,
                              ),
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
    final image = product.images.isNotEmpty ? product.images.first : '';

    return Card(
      child: ListTile(
        onTap: () => openProduct(product),
        leading: image.isEmpty
            ? const Icon(Icons.image)
            : Image.network(image, width: 60, height: 60, fit: BoxFit.cover),
        title: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: productPriceBlock(
          product,
          priceSize: 15,
          oldPriceSize: 11,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

class StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  StickySearchHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: const Color(0xFFF5F5F5),
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

