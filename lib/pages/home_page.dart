import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../core/cart_manager.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'checkout_page.dart';
import 'product_page.dart';
import 'admin_orders_page.dart';
import 'order_tracking_page.dart';
import 'activity_page.dart';
import 'my_orders_page.dart';
import 'profile_page.dart';
import 'admin_users_page.dart';

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
  final searchController = TextEditingController();
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
  final PageController heroController = PageController();
  int currentHeroIndex = 0;
  Timer? heroTimer;
  final GlobalKey cartIconKey = GlobalKey();
  final TextEditingController couponController = TextEditingController();
  final double freeShippingThreshold = 400;
  double discountValue = 0;
  String appliedCoupon = '';
  bool giftFinderExpanded = false;
  String giftRecipient = 'Oricine';
  String giftOccasion = 'Surpriză';
  String giftBudget = 'Toate';
  String giftFinderStatus = '';

  final accountNameController = TextEditingController();
  final accountEmailController = TextEditingController();
  final accountPasswordController = TextEditingController();
  final accountConfirmPasswordController = TextEditingController();
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  bool obscureLoginPassword = true;

  final Map<String, CartItem> cart = {};
  final Set<Product> favorites = {};
  final Set<String> favoriteKeys = {};
  final Map<String, int> favoriteQuantities = {};
  final List<Product> recentlyViewed = [];
  final List<Product> addedToCartHistory = [];
  final List<String> searchHistory = [];

  static const List<CategoryGroup> siteCategories = [
    CategoryGroup(
      title: 'Carduri Cadou',
      icon: Icons.card_giftcard,
      subcategories: [],
    ),
    CategoryGroup(
      title: 'Home & deco',
      icon: Icons.chair_outlined,
      subcategories: [
        'Lămpi solare',
        'Seturi mobilă grădină',
        'Mese',
        'Coșuri pentru rufe și ligheane',
        'Suporturi și accesorii de baie',
        'Oglinzi decorative',
        'Ceasuri decorative',
        'Birouri',
        'Scaune birou',
        'Plante artificiale',
        'Umbrele și pavilioane grădină',
        'Veioze și lămpi',
        'Scaune',
        'Rafturi',
        'Cuiere',
        'Veselă pentru masă și tacâmuri',
        'Covorașe intrare',
        'Coșuri picnic',
        'Mobilier gradină',
        'Accesorii pentru grădină',
        'Lanterne',
        'Balansoare și hamace',
        'Uscătoare rufe',
        'Mobilă living și biblioteci',
        'Dulapuri pantofi',
        'Mese grădină',
        'Măsuțe de toaletă',
        'Comode',
        'Șifoniere și dulapuri',
        'Oglinzi și mobilier baie',
        'Cutii alimentare',
        'Seturi mobilă bucătărie',
        'Prosoape',
        'Aranjamente florale',
        'Albume foto',
        'Vaze și boluri decorative',
        'Perne decorative',
        'Odorizante cameră',
        'Fețe de masă',
        'Suporturi lumânări',
        'Bucatărie și servire',
        'Accesorii grătar',
        'Accesorii decorative',
        'Corpuri de iluminat',
        'Cutii depozitare',
        'Ghivece și suporturi',
        'Etajere',
        'Lumânări și candele',
        'Rame foto',
        'Tăvi servire',
        'Umidificatoare',
        'Veselă desert',
      ],
    ),
    CategoryGroup(
      title: 'Jucării, Copii & Bebe',
      icon: Icons.toys_outlined,
      subcategories: [
        'Trambuline',
        'Căsuțe și corturi copii',
        'Prosoape și halate de baie copii',
        'Accesorii transport copii',
        'Fuste fete',
        'Rucsacuri și genți copii',
        'Jucării pentru plajă și nisip',
        'Jucării pentru dentiție',
        'Jucării zornăitoare',
        'Jucării de tras/împins',
        'Jucării interactive bebeluși',
        'Jucării de pluș',
        'Jucării interactive',
        'Jucării figurine',
        'Jucării de exterior',
        'Jocuri de îndemânare',
        'Păpuși',
        'Articole hrănire bebeluși',
        'Suzete și accesorii',
        'Mașinuțe',
        'Motociclete de jucărie',
        'Puzzle',
        'Piscine copii',
        'Seturi arheologice',
        'Seturi de artizanat',
        'Seturi de construcție',
        'Seturi pictură și desen',
      ],
    ),
    CategoryGroup(
      title: 'Party',
      icon: Icons.celebration_outlined,
      subcategories: [
        'Lumânări',
        'Accesorii party',
        'Magic POP-UPS',
        'Veselă party',
        'Baloane',
        'Artificii și confetti',
        'Pahare party',
        'Felicitări',
        'Șervețele party',
      ],
    ),
    CategoryGroup(
      title: 'Fashion',
      icon: Icons.checkroom_outlined,
      subcategories: [
        'Ochelari de soare bărbați',
        'Ochelari de soare damă',
        'Ochelari de soare copii',
        'Șlapi, papuci și saboți damă',
        'Șlapi și papuci bărbați',
        'Papuci și șlapi copii',
        'Sandale copii',
        'Pălării damă',
        'Șosete damă',
        'Șosete bărbați',
        'Rucsacuri damă',
        'Genți damă',
        'Genți laptop',
        'Huse tablete',
        'Portofele damă',
        'Umbrele bărbați',
        'Umbrele femei',
        'Ceasuri copii',
        'Rochii fete',
        'Bijuterii copii',
        'Eșarfe damă',
        'Cutii bijuterii',
        'Bijuterii damă',
        'Accesorii plajă',
        'Accesorii păr',
        'Brelocuri',
        'Măști și costume carnaval',
      ],
    ),
    CategoryGroup(
      title: 'Sport',
      icon: Icons.sports_soccer_outlined,
      subcategories: [
        'Haltere și gantere',
        'Extensoare și benzi elastice',
        'Mingi fitness',
        'Fitness și nutriție',
        'Scaune, mese și umbrele camping',
        'Food',
        'Rucsacuri',
        'Genți termo-izolante',
        'Accesorii fitness',
        'Saltele',
        'Trolere',
        'Corzi sărituri',
        'Bord-uri de darts',
        'Borsete sport',
        'Genți voiaj',
        'Bidoane și shakere',
        'Suport telefon',
        'Mănuși Sport',
        'Coșuri și panouri baschet',
        'Accesorii camping și drumeții',
        'Genți sport, fitness',
        'Mese biliard',
        'Mese foosball',
        'Steppere',
      ],
    ),
    CategoryGroup(
      title: 'Petshop',
      icon: Icons.pets_outlined,
      subcategories: [
        'Cuști, cotețe, tarcuri și colivii',
        'Ansambluri de joacă animale',
        'Culcușuri, perne si saltele pentru animale',
        'Zgărzi, lese și hamuri',
        'Jucării animale',
        'Litiere',
        'Perii, trimmere și clești animale',
        'Castroane și adăpători animale',
        'Genti si articole transport',
        'Accesorii litiere',
        'Echipament dresaj',
      ],
    ),
    CategoryGroup(
      title: 'Camera copilului',
      icon: Icons.child_care_outlined,
      subcategories: [
        'Mobilier',
        'Perne',
        'Păturici bebe',
        'Pușculițe',
        'Decorațiuni',
        'Covorașe copii',
        'Ceasuri',
        'Lămpi de veghe',
      ],
    ),
    CategoryGroup(
      title: 'Rechizite',
      icon: Icons.edit_note_outlined,
      subcategories: [
        'Penare',
        'Ghiozdane și genți',
        'Seturi rechizite',
        'Carnețele',
        'Agende și calendare',
        'Corectoare și radiere',
        'Creioane',
        'Semne de carte',
        'Stickere',
        'Cretă și table școlare',
        'Pixuri',
        'Creioane colorate și carioci',
        'Acuarele, pensule si blocuri de desen',
        'Hărți de perete și globuri pământești',
        'Suport carte și tabletă',
        'Markere',
        'Cuburi hârtie și note adezive',
        'Mape, serviete și clipboarduri',
      ],
    ),
    CategoryGroup(
      title: 'Îngrijire personală',
      icon: Icons.spa_outlined,
      subcategories: [
        'Oglinzi cosmetice',
        'Portfarduri și genți cosmetice',
        'Tatuaje temporare',
        'Suporturi ortopedice si orteze',
        'Îngrijire corp',
        'Accesorii machiaj',
        'Măști pentru ten și gomaje',
        'Aparate de masaj',
        'Aplicatoare și pensule machiaj',
        'Seturi de relaxare',
      ],
    ),
    CategoryGroup(
      title: 'Ambalare cadou',
      icon: Icons.redeem_outlined,
      subcategories: [
        'Hârtie ambalat',
        'Cutii băuturi',
        'Steluțe adezive',
        'Accesorii',
        'Cutii de cadou',
        'Pungi de cadou',
        'Lichidare de stoc',
      ],
    ),
  ];

  late Future<List<Product>> productsFuture;
  late Future<List<CategoryData>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    loadSavedDarkMode();
    productsFuture = fetchProducts();
    categoriesFuture = fetchCategories();
    loadSavedUser();
    loadSavedFavorites();
    loadSavedCart();
    loadPhase3Settings();
    startHeroAutoSlide();
  }

  @override
  void dispose() {
    searchController.dispose();
    accountNameController.dispose();
    accountEmailController.dispose();
    accountPasswordController.dispose();
    accountConfirmPasswordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    couponController.dispose();
    heroTimer?.cancel();
    heroController.dispose();
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

    if (!mounted) return;

    setState(() {
      loggedUserName = null;
      loggedUserEmail = null;
      accountMode = 'menu';
      selectedIndex = 4;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Te-ai delogat cu succes')),
    );
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
          ..addAll(
            products.where(
              (product) => favoriteKeys.contains(cartKey(product)),
            ),
          );
      });
    } catch (_) {
      // Favorites will be restored on the next successful products load.
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_product_keys', favoriteKeys.toList());
  }

  Future<void> loadSavedCart() async {
    final savedCart = await CartManager.loadCart();

    if (!mounted) return;

    setState(() {
      cart
        ..clear()
        ..addAll(savedCart);
    });
  }

  Future<void> saveCart() async {
    await CartManager.saveCart(cart);
  }

  Future<void> loadSavedDarkMode() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> loadPhase3Settings() async {
  final prefs = await SharedPreferences.getInstance();

  final savedViewedKeys =
      prefs.getStringList('analytics_recently_viewed') ?? [];

  final savedCartKeys =
      prefs.getStringList('analytics_added_to_cart_history') ?? [];

  final savedSearchHistory =
      prefs.getStringList('analytics_search_history') ?? [];

  try {
    final products = await productsFuture;

    if (!mounted) return;

    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;

      analyticsProductViews =
          prefs.getInt('analytics_product_views') ?? 0;

      analyticsAddToCart =
          prefs.getInt('analytics_add_to_cart') ?? 0;

      analyticsSearches =
          prefs.getInt('analytics_searches') ?? 0;

      recentlyViewed
        ..clear()
        ..addAll(
          savedViewedKeys
              .map((key) => products.where((p) => cartKey(p) == key).toList())
              .where((list) => list.isNotEmpty)
              .map((list) => list.first),
        );

      addedToCartHistory
        ..clear()
        ..addAll(
          savedCartKeys
              .map((key) => products.where((p) => cartKey(p) == key).toList())
              .where((list) => list.isNotEmpty)
              .map((list) => list.first),
        );

      searchHistory
        ..clear()
        ..addAll(savedSearchHistory);
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;

      analyticsProductViews =
          prefs.getInt('analytics_product_views') ?? 0;

      analyticsAddToCart =
          prefs.getInt('analytics_add_to_cart') ?? 0;

      analyticsSearches =
          prefs.getInt('analytics_searches') ?? 0;

      searchHistory
        ..clear()
        ..addAll(savedSearchHistory);
    });
  }
}

  void startHeroAutoSlide() {
    heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !heroController.hasClients) return;

      final nextIndex = (currentHeroIndex + 1) % 3;

      heroController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
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

  await prefs.setStringList(
    'analytics_recently_viewed',
    recentlyViewed.map((p) => cartKey(p)).toList(),
  );

  await prefs.setStringList(
    'analytics_added_to_cart_history',
    addedToCartHistory.map((p) => cartKey(p)).toList(),
  );

  await prefs.setStringList(
    'analytics_search_history',
    searchHistory,
  );
}

  void trackProductView() {
    analyticsProductViews++;
    saveAnalytics();
  }

  void trackAddToCart(Product product) {
  analyticsAddToCart++;

  addedToCartHistory.removeWhere(
    (p) => p.sku == product.sku,
  );

  addedToCartHistory.insert(0, product);

  saveAnalytics();
}

  void trackSearch(String query) {
  analyticsSearches++;

  final text = query.trim();

  if (text.isNotEmpty) {
    searchHistory.remove(text);
    searchHistory.insert(0, text);

    if (searchHistory.length > 20) {
      searchHistory.removeLast();
    }
  }

  saveAnalytics();
}

  Color get appBackgroundColor =>
      darkMode ? const Color(0xFF0F0F12) : const Color(0xFFF5F5F5);
  Color get appCardColor => darkMode ? const Color(0xFF1B1B20) : Colors.white;
  Color get appSurfaceColor =>
      darkMode ? const Color(0xFF24242A) : Colors.white;
  Color get appTextColor => darkMode ? Colors.white : Colors.black;
  Color get appMutedTextColor =>
      darkMode ? Colors.grey.shade400 : Colors.grey.shade700;
  Color get appBorderColor =>
      darkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

  void addRecentlyViewed(Product product) {
    setState(() {
      recentlyViewed.removeWhere((item) => cartKey(item) == cartKey(product));
      recentlyViewed.insert(0, product);

      if (recentlyViewed.length > 10) {
        recentlyViewed.removeRange(10, recentlyViewed.length);
      }
    });
  }

  String cartKey(Product product) =>
      product.sku.isNotEmpty ? product.sku : product.title;

  int stockFor(Product product) {
    final parsed = int.tryParse(product.stock.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  int get cartItemCount =>
      cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get cartTotal =>
      cart.values.fold<double>(0, (sum, item) => sum + item.total);

  void flyToCartFrom(BuildContext sourceContext) {
    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final cartBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (sourceBox == null || cartBox == null) {
      return;
    }

    final start = sourceBox.localToGlobal(
      sourceBox.size.center(Offset.zero),
      ancestor: overlay,
    );

    final end = cartBox.localToGlobal(
      cartBox.size.center(Offset.zero),
      ancestor: overlay,
    );

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1250),
          curve: Curves.easeInOutCubicEmphasized,
          onEnd: () => entry.remove(),
          builder: (context, value, child) {
            final x = start.dx + ((end.dx - start.dx) * value);

            final arcHeight = 180 * (1 - (value - 0.5).abs() * 2);

            final y = start.dy + ((end.dy - start.dy) * value) - arcHeight;

            final scale = 1.25 - (0.55 * value);

            return Positioned(
              left: x - 26,
              top: y - 26,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: 1,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.45),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  Future<void> reorderOrderItems(List<dynamic> orderItems) async {
    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda nu are produse salvate.')),
      );
      return;
    }

    try {
      final products = await productsFuture;
      var addedCount = 0;
      final missingProducts = <String>[];

      setState(() {
        for (final item in orderItems) {
          if (item is! Map) continue;

          final sku = (item['sku'] ?? '').toString().trim();
          final title = (item['title'] ?? '').toString().trim();
          final quantity = int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;

          Product? matchedProduct;

          for (final product in products) {
            final productSku = product.sku.trim();
            final productTitle = product.title.trim();

            final skuMatches =
                sku.isNotEmpty && productSku.isNotEmpty && productSku == sku;

            final titleMatches =
                title.isNotEmpty &&
                productTitle.toLowerCase() == title.toLowerCase();

            if (skuMatches || titleMatches) {
              matchedProduct = product;
              break;
            }
          }

          if (matchedProduct == null) {
            if (title.isNotEmpty) missingProducts.add(title);
            return;
          }

          final key = cartKey(matchedProduct);

          if (cart.containsKey(key)) {
            cart[key]!.quantity += quantity;
          } else {
            cart[key] = CartItem(
              product: matchedProduct,
              quantity: quantity,
            );
          }

          addedCount += quantity;
        }

        cartBounce = true;
        selectedIndex = 3;
      });

      await saveCart();

      Future.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;

        setState(() {
          cartBounce = false;
        });
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addedCount > 0
                ? '$addedCount produse au fost adăugate în coș.'
                : 'Nu am găsit produse disponibile pentru această comandă.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      if (missingProducts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unele produse nu mai sunt disponibile: ${missingProducts.take(2).join(', ')}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut reface comanda: $error')),
      );
    }
  }

  void addToCart(Product product, [int quantity = 1]) {
    final key = cartKey(product);
    final stock = stockFor(product);
    final currentQuantity = cart[key]?.quantity ?? 0;
    final requestedQuantity = quantity < 1 ? 1 : quantity;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produsul nu este disponibil momentan.'),
        ),
      );
      return;
    }

    if (currentQuantity + requestedQuantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stoc disponibil: $stock buc.'),
        ),
      );
      return;
    }

    trackAddToCart(product);

    setState(() {
      if (cart.containsKey(key)) {
        cart[key]!.quantity += requestedQuantity;
      } else {
        cart[key] = CartItem(
          product: product,
          quantity: requestedQuantity,
        );
      }

      cartBounce = true;
    });

    saveCart();

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;

      setState(() {
        cartBounce = false;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requestedQuantity == 1
              ? '${product.title} adăugat în coș'
              : '$requestedQuantity x ${product.title} adăugate în coș',
        ),
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
    final item = cart[key];
    if (item == null) return;

    final stock = stockFor(item.product);

    if (item.quantity >= stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stoc disponibil: $stock buc.'),
        ),
      );
      return;
    }

    setState(() => item.quantity++);
    saveCart();
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

    saveCart();
  }

  void removeFromCart(String key) {
    setState(() => cart.remove(key));
    saveCart();
  }

  void clearCart() {
    setState(() {
      cart.clear();
      discountValue = 0;
      appliedCoupon = '';
      couponController.clear();
    });

    CartManager.clearCart();
  }

  void applyCoupon() {
    final code = couponController.text.trim().toUpperCase();

    if (code == 'GIFT10') {
      setState(() {
        appliedCoupon = code;
        discountValue = cartTotal * 0.10;
      });

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cod promo aplicat: -10%')));

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cod invalid')));
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

    final selectedGroups = siteCategories
        .where((group) => normalizeCategory(group.title) == selected)
        .toList();
    if (selectedGroups.isEmpty) return false;

    return selectedGroups.first.subcategories
        .map(normalizeCategory)
        .contains(productCategory);
  }

  int countForCategory(List<Product> products, String category) {
    if (category == 'Toate') return products.length;
    final normalized = normalizeCategory(category);
    final groups = siteCategories
        .where((group) => normalizeCategory(group.title) == normalized)
        .toList();

    if (groups.isNotEmpty) {
      final accepted = {
        normalizeCategory(groups.first.title),
        ...groups.first.subcategories.map(normalizeCategory),
      };
      return products
          .where(
            (product) => accepted.contains(normalizeCategory(product.category)),
          )
          .length;
    }

    return products
        .where((product) => normalizeCategory(product.category) == normalized)
        .length;
  }

  CategoryData? merchantCategoryFor(
    List<CategoryData> categories,
    String category,
  ) {
    final normalized = normalizeCategory(category);

    for (final item in categories) {
      if (normalizeCategory(item.name) == normalized) return item;
    }

    return null;
  }

  String merchantImageForCategory(
    List<CategoryData> categories,
    List<Product> products,
    String category,
  ) {
    final merchantCategory = merchantCategoryFor(categories, category);
    final parentGroup = parentCategoryFor(category);

    if (merchantCategory != null) {
      if (parentGroup != null) {
        if (merchantCategory.imageSubcategory.isNotEmpty)
          return merchantCategory.imageSubcategory;
        if (merchantCategory.menuImage.isNotEmpty)
          return merchantCategory.menuImage;
        if (merchantCategory.menuIcon.isNotEmpty)
          return merchantCategory.menuIcon;
      } else {
        if (merchantCategory.menuImage.isNotEmpty)
          return merchantCategory.menuImage;
        if (merchantCategory.imageSubcategory.isNotEmpty)
          return merchantCategory.imageSubcategory;
        if (merchantCategory.menuIcon.isNotEmpty)
          return merchantCategory.menuIcon;
      }
    }

    // Fallback: if MerchantPro has no dedicated image for this category,
    // use the first product image so the UI never remains blank.
    Iterable<Product> candidates;

    if (category == 'Toate') {
      candidates = products;
    } else {
      final normalized = normalizeCategory(category);
      final groups = siteCategories
          .where((group) => normalizeCategory(group.title) == normalized)
          .toList();

      if (groups.isNotEmpty) {
        final accepted = {
          normalizeCategory(groups.first.title),
          ...groups.first.subcategories.map(normalizeCategory),
        };
        candidates = products.where(
          (product) => accepted.contains(normalizeCategory(product.category)),
        );
      } else {
        candidates = products.where(
          (product) => normalizeCategory(product.category) == normalized,
        );
      }
    }

    for (final product in candidates) {
      if (product.images.isNotEmpty && product.images.first.trim().isNotEmpty) {
        return product.images.first;
      }
    }

    return '';
  }

  Widget imageThumb(
    String imageUrl, {
    IconData fallbackIcon = Icons.category_outlined,
    double height = 84,
    double width = double.infinity,
    BorderRadius? borderRadius,
  }) {
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
                color: appBorderColor,
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
      final matchesSearch =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);

      return matchesSearch && matchesSelectedCategory(product);
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(
        a.dateModified.isNotEmpty ? a.dateModified : a.dateCreated,
      );
      final bDate = DateTime.tryParse(
        b.dateModified.isNotEmpty ? b.dateModified : b.dateCreated,
      );

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

  int productsAnimationSeed(Product product) {
    return product.title.length % 6;
  }

  List<Product> aiGiftFinderMatches(List<Product> products) {
    final recipientKeywords = <String, List<String>>{
      'Copil': [
        'jucării',
        'copii',
        'bebe',
        'puzzle',
        'pluș',
        'figurine',
        'păpuși',
        'rechizite',
        'camera copilului',
      ],
      'Ea': [
        'damă',
        'bijuterii',
        'genți',
        'fashion',
        'cosmetice',
        'portfard',
        'eșarfe',
        'decorațiuni',
      ],
      'El': [
        'bărbați',
        'sport',
        'camping',
        'fitness',
        'grătar',
        'birou',
        'ceasuri',
      ],
      'Casă': [
        'home',
        'deco',
        'decorative',
        'bucătărie',
        'servire',
        'lămpi',
        'vaze',
        'rame',
        'lumânări',
      ],
      'Pet': ['petshop', 'animale', 'zgărzi', 'jucării animale', 'culcușuri'],
      'Oricine': ['cadou', 'party', 'carduri', 'home', 'fashion'],
    };

    final occasionKeywords = <String, List<String>>{
      'Zi de naștere': [
        'party',
        'baloane',
        'felicitări',
        'lumânări',
        'cadou',
        'jucării',
      ],
      'Casă nouă': [
        'home',
        'deco',
        'bucătărie',
        'servire',
        'vaze',
        'rame',
        'lămpi',
      ],
      'Relaxare': [
        'relaxare',
        'masaj',
        'lumânări',
        'hamace',
        'perne',
        'odorizante',
      ],
      'Outdoor': ['camping', 'grădină', 'sport', 'picnic', 'hamace', 'umbrele'],
      'Surpriză': ['cadou', 'premium', 'decorative', 'party', 'fashion'],
    };

    bool fitsBudget(Product product) {
      final price = priceValue(product);
      switch (giftBudget) {
        case 'sub 50 Lei':
          return price <= 50;
        case '50-150 Lei':
          return price >= 50 && price <= 150;
        case '150-400 Lei':
          return price >= 150 && price <= 400;
        case '400+ Lei':
          return price >= 400;
        case 'Toate':
        default:
          return true;
      }
    }

    int score(Product product) {
      final haystack =
          '${product.title} ${product.category} ${product.description} ${product.shortDescription}'
              .toLowerCase();
      var value = 0;

      for (final keyword
          in recipientKeywords[giftRecipient] ?? const <String>[]) {
        if (haystack.contains(keyword.toLowerCase())) value += 4;
      }

      for (final keyword
          in occasionKeywords[giftOccasion] ?? const <String>[]) {
        if (haystack.contains(keyword.toLowerCase())) value += 3;
      }

      if (product.discountPercent > 0) value += 2;
      if (favoriteKeys.contains(cartKey(product))) value += 2;
      if (recentlyViewed.any((item) => cartKey(item) == cartKey(product)))
        value += 1;

      return value;
    }

    final ranked = products.where(fitsBudget).toList()
      ..sort((a, b) {
        final scoreCompare = score(b).compareTo(score(a));
        if (scoreCompare != 0) return scoreCompare;
        return priceValue(a).compareTo(priceValue(b));
      });

    return ranked.take(8).toList();
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
      extendBody: true,
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appCardColor,
        foregroundColor: appTextColor,
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        color: appBackgroundColor,
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BottomNavigationBar(
            backgroundColor: darkMode
                ? const Color(0xFF1B1B20).withOpacity(0.94)
                : Colors.white.withOpacity(0.92),
            currentIndex: selectedIndex,
            selectedItemColor: primaryColor,
            unselectedItemColor: darkMode ? Colors.grey.shade500 : Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: 'Categorii',
              ),
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
                  scale: cartBounce ? 1.55 : 1,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  child: Stack(
                    key: cartIconKey,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedRotation(
                        turns: cartBounce ? 0.09 : 0,
                        duration: const Duration(milliseconds: 520),
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
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                label: loggedUserName != null && loggedUserName!.isNotEmpty
                    ? loggedUserName!
                    : 'Cont',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget badge(int value) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          color: darkMode ? const Color(0xFF24242A) : Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    Widget productSkeletonCard() {
      return Container(
        decoration: BoxDecoration(
          color: appCardColor,
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
      baseColor: darkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: darkMode ? Colors.grey.shade700 : Colors.grey.shade100,
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
              mainAxisExtent: 450,
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Eroare: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: appTextColor),
              ),
            ),
          );
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
            final dynamicCategories = products
                .map((product) => product.category.trim())
                .where((category) => category.isNotEmpty)
                .toSet();
            final visibleSubcategories = selectedMainGroup == null
                ? <String>[]
                : selectedMainGroup.subcategories
                      .where(
                        (subcategory) =>
                            dynamicCategories.contains(subcategory),
                      )
                      .toList();
            final showSubcategories =
                searchQuery.trim().isEmpty &&
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
                    backgroundColor: appBackgroundColor,
                    child: Container(
                      color: appBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: searchBox(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: searchSuggestionsPanel(products)),
                if (showCategoryNavigation)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickySearchHeaderDelegate(
                      height: 92,
                      backgroundColor: appBackgroundColor,
                      child: Container(
                        color: appBackgroundColor,
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
                        aiGiftFinderSection(products),
                        const SizedBox(height: 20),
                        categoryChips(categories, products, merchantCategories),
                        const SizedBox(height: 14),
                        sortBar(),
                        const SizedBox(height: 20),
                        recentlyViewedSection(),
                        if (recentlyViewed.isNotEmpty)
                          const SizedBox(height: 22),
                        Text(
                          showSubcategories
                              ? 'Subcategorii ${selectedMainGroup.title}'
                              : '${filteredProducts.length} produse',
                          style: TextStyle(
                            color: appTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showSubcategories) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Alege o subcategorie pentru a vedea produsele.',
                            style: TextStyle(color: appMutedTextColor),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 210,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return mainCategoryAllProductsCard(
                            selectedMainGroup.title,
                            countForCategory(products, selectedMainGroup.title),
                            merchantImageForCategory(
                              merchantCategories,
                              products,
                              selectedMainGroup.title,
                            ),
                          );
                        }
                        final subcategory = visibleSubcategories[index - 1];
                        return subcategoryCard(
                          subcategory,
                          countForCategory(products, subcategory),
                          merchantImageForCategory(
                            merchantCategories,
                            products,
                            subcategory,
                          ),
                        );
                      }, childCount: visibleSubcategories.length + 1),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 365,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            productCard(filteredProducts[index]),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!;

        return FutureBuilder<List<CategoryData>>(
          future: categoriesFuture,
          builder: (context, categorySnapshot) {
            final merchantCategories = categorySnapshot.data ?? [];
            final dynamicCategories = products
                .map((product) => product.category.trim())
                .where((category) => category.isNotEmpty)
                .toSet();
            final mappedValues = <String>{
              for (final group in siteCategories) ...[
                group.title,
                ...group.subcategories,
              ],
            };
            final otherCategories =
                dynamicCategories
                    .where((category) => !mappedValues.contains(category))
                    .toList()
                  ..sort();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: appCardColor,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageThumb(
                        merchantImageForCategory(
                          merchantCategories,
                          products,
                          'Toate',
                        ),
                        fallbackIcon: Icons.grid_view_rounded,
                        height: 46,
                        width: 46,
                      ),
                    ),
                    title: Text(
  'Toate produsele',
  style: TextStyle(
    color: appTextColor,
    fontWeight: FontWeight.bold,
  ),
),
subtitle: Text('${products.length} produse'),
trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => setState(() {
                      selectedCategory = 'Toate';
                      showMainCategoryProducts = false;
                      selectedIndex = 0;
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                ...siteCategories.map((group) {
                  final groupCount = countForCategory(products, group.title);
                  final visibleSubcategories = group.subcategories
                      .where(
                        (subcategory) =>
                            dynamicCategories.contains(subcategory),
                      )
                      .toList();

                  if (visibleSubcategories.isEmpty) {
                    return Card(
                      color: appCardColor,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageThumb(
                            merchantImageForCategory(
                              merchantCategories,
                              products,
                              group.title,
                            ),
                            fallbackIcon: group.icon,
                            height: 46,
                            width: 46,
                          ),
                        ),
                        title: Text(
  group.title,
  style: TextStyle(
    color: appTextColor,
    fontWeight: FontWeight.bold,
  ),
),
                        subtitle: Text('$groupCount produse'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => setState(() {
                          selectedCategory = group.title;
                          showMainCategoryProducts = false;
                          selectedIndex = 0;
                        }),
                      ),
                    );
                  }

                  return Card(
                      color: appCardColor,
                    child: ExpansionTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageThumb(
                          merchantImageForCategory(
                            merchantCategories,
                            products,
                            group.title,
                          ),
                          fallbackIcon: group.icon,
                          height: 46,
                          width: 46,
                        ),
                      ),
                      title: Text(
  group.title,
  style: TextStyle(
    color: appTextColor,
    fontWeight: FontWeight.bold,
  ),
),
                      subtitle: Text('$groupCount produse'),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 72,
                            right: 16,
                          ),
                          title: Text('Toate din ${group.title}'),
                          trailing: Text('$groupCount'),
                          onTap: () => setState(() {
                            selectedCategory = group.title;
                            showMainCategoryProducts = false;
                            selectedIndex = 0;
                          }),
                        ),
                        ...visibleSubcategories.map((subcategory) {
                          final count = countForCategory(products, subcategory);
                          return ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 72,
                              right: 16,
                            ),
                            title: Text(subcategory),
                            trailing: Text('$count'),
                            onTap: () => setState(() {
                              selectedCategory = subcategory;
                              showMainCategoryProducts = false;
                              selectedIndex = 0;
                            }),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                if (otherCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: appCardColor,
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.more_horiz,
                        color: primaryColor,
                      ),
                      title: const Text(
                        'Alte categorii',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${otherCategories.length} categorii'),
                      children: otherCategories
                          .map(
                            (category) => ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 72,
                                right: 16,
                              ),
                              title: Text(category),
                              trailing: Text(
                                '${countForCategory(products, category)}',
                              ),
                              onTap: () => setState(() {
                                selectedCategory = category;
                                showMainCategoryProducts = false;
                                selectedIndex = 0;
                              }),
                            ),
                          )
                          .toList(),
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

  List<Product> smartSuggestions(List<Product> products) {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty || query.length < 2) {
      return [];
    }

    return products
        .where((product) {
          return product.title.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query);
        })
        .take(5)
        .toList();
  }

  Widget searchSuggestionsPanel(List<Product> products) {
    final suggestions = smartSuggestions(products);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final product = suggestions[index];
          final image = product.images.isNotEmpty ? product.images.first : '';

          return ListTile(
            dense: true,
            onTap: () {
              FocusScope.of(context).unfocus();

              searchController.clear();

              setState(() {
                searchQuery = '';
              });

              openProduct(product);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image.isEmpty
                  ? Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
            ),
            title: Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              product.price,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.north_west_rounded, color: primaryColor),
          );
        },
      ),
    );
  }

  Widget searchBox() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorderColor),
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: appTextColor),
        onChanged: (value) {
          if (value.trim().isNotEmpty) {
            trackSearch(value);
          }

          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Caută produse...',
          hintStyle: TextStyle(color: appMutedTextColor),
          prefixIcon: Icon(Icons.search, color: appMutedTextColor),
          suffixIcon: searchQuery.trim().isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: appMutedTextColor),
                  onPressed: () {
                    searchController.clear();

                    setState(() {
                      searchQuery = '';
                    });
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget promoBanner() {
    final banners = [
      {
        'title': 'Cadouri memorabile',
        'subtitle': 'Surprize premium pentru orice ocazie',
        'icon': Icons.card_giftcard,
      },
      {
        'title': 'Transport gratuit',
        'subtitle': 'La comenzile peste 400 Lei',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'title': 'GiftDesign Premium',
        'subtitle': 'Experiență modernă de shopping',
        'icon': Icons.auto_awesome,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: heroController,
            onPageChanged: (index) {
              setState(() {
                currentHeroIndex = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (_, index) {
              final banner = banners[index];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Container(
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 28,
                      bottom: 22,
                      child: Icon(
                        banner['icon'] as IconData,
                        color: Colors.white.withOpacity(0.13),
                        size: 108,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Icon(
                              banner['icon'] as IconData,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            banner['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['subtitle'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final active = currentHeroIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget categoryNavigationBar({
    required String title,
    required String breadcrumb,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor),
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
                color: appSurfaceColor,
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
                  style: TextStyle(color: appMutedTextColor, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
        Text(
          'Văzute recent',
          style: TextStyle(
            color: appTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
              final image = product.images.isNotEmpty
                  ? product.images.first
                  : '';

              return GestureDetector(
                onTap: () => openProduct(product),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appCardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: appBorderColor),
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
                                fadeInDuration: const Duration(
                                  milliseconds: 250,
                                ),
                                placeholder: (_, __) => Container(
                                  width: 72,
                                  height: 88,
                                  color: Colors.grey.shade200,
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.image_outlined),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: appTextColor,
                              ),
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
                                color: appMutedTextColor,
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

  Widget aiGiftFinderSection(List<Product> products) {
    final matches = giftFinderStatus.isEmpty
        ? <Product>[]
        : aiGiftFinderMatches(products);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                giftFinderExpanded = !giftFinderExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistent Cadouri',
                        style: TextStyle(
                          color: appTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Alege mai ușor cadoul perfect.',
                        style: TextStyle(
                          color: appMutedTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: giftFinderExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                giftOptionGroup(
                  title: 'Pentru cine?',
                  value: giftRecipient,
                  options: const [
                    'Oricine',
                    'Ea',
                    'El',
                    'Copil',
                    'Casă',
                    'Pet',
                  ],
                  onSelected: (value) {
                    setState(() {
                      giftRecipient = value;
                      giftFinderStatus = '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                giftOptionGroup(
                  title: 'Ocazie',
                  value: giftOccasion,
                  options: const [
                    'Surpriză',
                    'Zi de naștere',
                    'Casă nouă',
                    'Relaxare',
                    'Outdoor',
                  ],
                  onSelected: (value) {
                    setState(() {
                      giftOccasion = value;
                      giftFinderStatus = '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                giftOptionGroup(
                  title: 'Buget',
                  value: giftBudget,
                  options: const [
                    'Toate',
                    'sub 50 Lei',
                    '50-150 Lei',
                    '150-400 Lei',
                    '400+ Lei',
                  ],
                  onSelected: (value) {
                    setState(() {
                      giftBudget = value;
                      giftFinderStatus = '';
                    });
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        giftFinderStatus =
                            'Cadouri recomandate pentru $giftRecipient • $giftOccasion • $giftBudget';
                      });
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Găsește cadouri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (giftFinderStatus.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    giftFinderStatus,
                    style: TextStyle(
                      color: appTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (matches.isEmpty)
                    Text(
                      'Nu am găsit potriviri bune. Încearcă alt buget sau altă ocazie.',
                      style: TextStyle(color: appMutedTextColor),
                    )
                  else
                    SizedBox(
                      height: 236,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            giftProductCard(matches[index]),
                      ),
                    ),
                ],
              ],
            ),
            crossFadeState: giftFinderExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget giftOptionGroup({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: appTextColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = value == option;
            return ChoiceChip(
              selected: selected,
              label: Text(option),
              backgroundColor: appSurfaceColor,
              selectedColor: primaryColor.withOpacity(darkMode ? 0.24 : 0.14),
              checkmarkColor: primaryColor,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: TextStyle(
                color: selected ? primaryColor : appTextColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.w700,
                fontSize: 13,
              ),
              side: BorderSide(color: selected ? primaryColor : appBorderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget giftProductCard(Product product) {
    final image = product.images.isNotEmpty ? product.images.first : '';

    return GestureDetector(
      onTap: () => openProduct(product),
      child: Container(
        width: 165,
        decoration: BoxDecoration(
          color: appSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appBorderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageThumb(
              image,
              height: 105,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: appTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    productPriceBlock(product, priceSize: 14, oldPriceSize: 10),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          addToCart(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Adaugă',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  Widget categoryChips(
    List<String> categories,
    List<Product> products,
    List<CategoryData> merchantCategories,
  ) {
    final visibleCategories = categories
        .where((category) => category != 'Toate')
        .toList();

    return SizedBox(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCategories.length,
        itemBuilder: (context, index) {
          final category = visibleCategories[index];
          final selected = selectedCategory == category;
          final image = merchantImageForCategory(
            merchantCategories,
            products,
            category,
          );
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
                color: appCardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? primaryColor
                      : (darkMode ? Colors.white24 : Colors.grey.shade200),
                  width: selected ? 2 : 1,
                ),
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
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
                        color: darkMode
                            ? Colors.white
                            : (selected ? primaryColor : Colors.black),
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

  Widget mainCategoryAllProductsCard(
    String category,
    int count,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          showMainCategoryProducts = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isEmpty
                ? Container(
                    color: primaryColor,
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white70,
                      size: 42,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: primaryColor,
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
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
                      Text(
                        'Toate din $category',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count produse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
        decoration: BoxDecoration(
          color: appCardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                imageThumb(
                  imageUrl,
                  height: 104,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: primaryColor,
                      size: 18,
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
                  Text(
                    subcategory,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count produse',
                    style: TextStyle(color: appMutedTextColor, fontSize: 13),
                  ),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
    final isNew =
        parsedDate != null &&
        DateTime.now().difference(parsedDate).inDays <= 30;

    final animationSeed = productsAnimationSeed(product);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (animationSeed * 80)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => openProduct(product),
        child: Container(
          decoration: BoxDecoration(
            color: darkMode ? const Color(0xFF1B1B20) : Colors.white,
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
                          child: const Center(
                            child: Icon(Icons.image_outlined),
                          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (isNew)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'NOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () => toggleFavorite(product),
                      child: AnimatedScale(
                        scale: isFavorite ? 1.15 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.elasticOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.red.withOpacity(0.12)
                                : Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(isFavorite),
                              color: isFavorite ? Colors.red : primaryColor,
                              size: 21,
                            ),
                          ),
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
                        style: TextStyle(
                          color: appMutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      productPriceBlock(product),
                      const SizedBox(height: 9),
                      Builder(
                        builder: (buttonContext) {
                          return SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                flyToCartFrom(buttonContext);
                                addToCart(product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 17,
                              ),
                              label: const Text(
                                'Adaugă',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget productGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'Nu am găsit produse',
          style: TextStyle(color: appTextColor),
        ),
      );
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

  Widget favoriteQuantitySelector(Product product) {
    final key = cartKey(product);
    final stock = stockFor(product);
    final selectedQuantity = favoriteQuantities[key] ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: selectedQuantity > 1
                ? () {
                    setState(() {
                      favoriteQuantities[key] = selectedQuantity - 1;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove_circle_outline,
                color: selectedQuantity > 1 ? primaryColor : Colors.grey,
                size: 22,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              selectedQuantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: selectedQuantity < stock
                ? () {
                    setState(() {
                      favoriteQuantities[key] = selectedQuantity + 1;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add_circle_outline,
                color: selectedQuantity < stock ? primaryColor : Colors.grey,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFavorites() {
    if (favorites.isEmpty) {
      return Center(
        child: Text(
          'Nu ai produse favorite',
          style: TextStyle(color: appTextColor),
        ),
      );
    }

    final list = favorites.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final product = list[index];
        final image = product.images.isNotEmpty ? product.images.first : '';
        final favoriteKey = cartKey(product);
        final selectedQuantity = favoriteQuantities[favoriteKey] ?? 1;
        final stock = stockFor(product);

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openProduct(product),
          child: Card(
            color: appCardColor,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: appTextColor,
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

                        const SizedBox(height: 6),

                        Text(
                          stock > 0
                              ? 'Stoc disponibil: $stock buc.'
                              : 'Stoc indisponibil',
                          style: TextStyle(
                            color: stock > 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            favoriteQuantitySelector(product),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
  child: Builder(
    builder: (buttonContext) {
      return ElevatedButton.icon(
        onPressed: stock > 0
            ? () {
                flyToCartFrom(buttonContext);
                addToCart(product, selectedQuantity);
              }
            : null,
        icon: const Icon(
          Icons.shopping_cart_outlined,
          size: 18,
        ),
        label: const Text('Adaugă în coș'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    },
  ),
),

                            const SizedBox(width: 10),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => toggleFavorite(product),

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
      prefixIcon: Icon(icon, color: appMutedTextColor),
      labelStyle: TextStyle(color: appMutedTextColor),
      filled: true,
      fillColor: appSurfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: appBorderColor),
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
      final isAdmin =
    loggedUserEmail?.toLowerCase() ==
    'overclockmanager@gmail.com';
      return ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          170 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.account_circle, size: 90, color: primaryColor),
          const SizedBox(height: 18),
          Text(
            loggedUserName ?? 'Client GiftDesign',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTextColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loggedUserEmail ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMutedTextColor, fontSize: 15),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: logoutAccount,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Delogare'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          profileQuickActions(),

          const SizedBox(height: 16),

          analyticsDashboard(),

          const SizedBox(height: 16),

          if (isAdmin) ...[
  SizedBox(
    height: 52,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminOrdersPage(),
          ),
        );
      },
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Admin comenzi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
  const SizedBox(height: 12),

  SizedBox(
    height: 52,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminUsersPage(),
          ),
        );
      },
      icon: const Icon(Icons.people_alt_outlined),
      label: const Text('Admin clienți'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
  const SizedBox(height: 12),
],



          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: logoutAccount,
              icon: const Icon(Icons.logout),
              label: const Text('Delogare cont'),
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
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        170 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const SizedBox(height: 18),
        const Icon(
          Icons.account_circle_outlined,
          size: 72,
          color: primaryColor,
        ),
        const SizedBox(height: 14),
        Text(
          'Contul meu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Intră în cont sau creează unul nou pentru a salva comenzile și datele tale.',
          textAlign: TextAlign.center,
          style: TextStyle(color: appMutedTextColor),
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

  Widget profileQuickActions() {
    return Column(
      children: [
        SwitchListTile(
          value: darkMode,
          activeColor: primaryColor,
          title: Text(
            'Dark mode',
            style: TextStyle(
              color: appTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Comută aplicația în modul întunecat',
            style: TextStyle(color: appMutedTextColor),
          ),
          secondary: const Icon(Icons.dark_mode_outlined, color: primaryColor),
          onChanged: saveDarkMode,
        ),
        const SizedBox(height: 12),
        Card(
          color: appCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: primaryColor,
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profilul meu',
                          style: TextStyle(
                            color: appTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completează datele de facturare și livrare.',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: appCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyOrdersPage(
                    onReorder: reorderOrderItems,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: primaryColor,
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comenzile mele',
                          style: TextStyle(
                            color: appTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vezi istoricul comenzilor tale și statusul lor.',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: appCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderTrackingPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: primaryColor,
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order tracking',
                          style: TextStyle(
                            color: appTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Urmărește comanda, statusul și AWB-ul.',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
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
          Text(
            'Analytics',
            style: TextStyle(
              color: appTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityPage(
                          title: 'Produse vizualizate',
                          products: recentlyViewed,
                          onProductTap: openProduct,
                          onSearchTap: (_) {},
                        ),
                      ),
                    );
                  },
                  child: analyticsTile(
                    icon: Icons.visibility_outlined,
                    label: 'Vizualizări',
                    value: analyticsProductViews.toString(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityPage(
                          title: 'Adăugate în coș',
                          products: addedToCartHistory,
                          onProductTap: openProduct,
                          onSearchTap: (_) {},
                        ),
                      ),
                    );
                  },
                  child: analyticsTile(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Add to cart',
                    value: analyticsAddToCart.toString(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityPage(
                          title: 'Căutări',
                          searches: searchHistory,
                          onProductTap: (_) {},
                          onSearchTap: (query) {
                            setState(() {
                              selectedIndex = 0;
                              searchQuery = query;
                              searchController.text = query;
                            });

                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  child: analyticsTile(
                    icon: Icons.search,
                    label: 'Căutări',
                    value: analyticsSearches.toString(),
                  ),
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
            style: TextStyle(
              color: appTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
            Expanded(
              child: Text(
                'Creează cont',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: accountNameController,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration(
            'Nume și prenume',
            Icons.person_outline,
          ),
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
          obscureText: obscureLoginPassword,
          textInputAction: TextInputAction.next,
          decoration: accountFieldDecoration(
  'Parolă',
  Icons.lock_outline,
).copyWith(
  suffixIcon: IconButton(
    onPressed: () {
      setState(() {
        obscureLoginPassword = !obscureLoginPassword;
      });
    },
    icon: Image.asset(
  obscureLoginPassword
      ? 'assets/images/dragon_eye_closed.png'
      : 'assets/images/dragon_eye_open.png',
  width: 26,
  height: 26,
),
  ),
),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountConfirmPasswordController,
          obscureText: true,
          decoration: accountFieldDecoration(
            'Confirmă parola',
            Icons.lock_reset,
          ),
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
                    const SnackBar(content: Text('Cont creat cu succes')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Eroare server')));
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
            Expanded(
              child: Text(
                'Autentificare',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
          obscureText: obscureLoginPassword,
          decoration: accountFieldDecoration(
  'Parolă',
  Icons.lock_outline,
).copyWith(
  suffixIcon: IconButton(
    onPressed: () {
      setState(() {
        obscureLoginPassword = !obscureLoginPassword;
      });
    },
    icon: Image.asset(
  obscureLoginPassword
      ? 'assets/images/dragon_eye_closed.png'
      : 'assets/images/dragon_eye_open.png',
  width: 26,
  height: 26,
),
  ),
),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final email = loginEmailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Introdu emailul mai întâi.')),
                );
                return;
              }

              try {
                final response = await http.post(
                  Uri.parse('$apiBaseUrl/forgot-password'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'email': email,
                  }),
                );

                final decoded = jsonDecode(response.body);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      decoded['message'] ??
                          'Dacă emailul există, vei primi un link de resetare.',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nu am putut trimite emailul.')),
                );
              }
            },
            child: const Text('Ai uitat parola?'),
          ),
        ),
        const SizedBox(height: 14),
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
                  final userData = Map<String, dynamic>.from(decoded['user']);
                  userData['token'] = decoded['token'];

                  await saveUserSession(userData);

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Login reușit')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(decoded['error'] ?? 'Login eșuat')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Eroare server')));
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.08),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Coșul tău este gol',
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adaugă produse premium și fă pe cineva fericit ✨',
                textAlign: TextAlign.center,
                style: TextStyle(color: appMutedTextColor, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final items = cart.entries.toList();
    final progress = (cartTotal / freeShippingThreshold).clamp(0, 1).toDouble();
    final remaining = freeShippingThreshold - cartTotal;
    final shippingCost = cartTotal >= freeShippingThreshold ? 0.0 : 24.9;
    final finalTotal = (cartTotal + shippingCost - discountValue)
        .clamp(0, double.infinity)
        .toDouble();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 295),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appCardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: appBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          remaining <= 0
                              ? 'Ai transport GRATUIT 🎉'
                              : 'Mai adaugi ${remaining.toStringAsFixed(0)} Lei pentru transport gratuit',
                          style: TextStyle(
                            color: appTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: darkMode
                          ? Colors.white12
                          : Colors.grey.shade300,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...items.map((entry) {
              final key = entry.key;
              final item = entry.value;
              final product = item.product;
              final image = product.images.isNotEmpty
                  ? product.images.first
                  : '';

              return Dismissible(
                key: Key(key),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  removeFromCart(key);
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => openProduct(product),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appCardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: appBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: image.isEmpty
                              ? Container(
                                  width: 90,
                                  height: 90,
                                  color: primaryColor.withOpacity(0.08),
                                  child: const Icon(Icons.image_outlined),
                                )
                              : CachedNetworkImage(
                                  imageUrl: image,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 90,
                                    height: 90,
                                    color: appBorderColor,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 90,
                                    height: 90,
                                    color: primaryColor.withOpacity(0.08),
                                    child: const Icon(Icons.image_outlined),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: appTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              productPriceBlock(
                                product,
                                priceSize: 15,
                                oldPriceSize: 11,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  quantityButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      decreaseQuantity(key);
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        color: appTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  quantityButton(
                                    icon: Icons.add,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      increaseQuantity(key);
                                    },
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.swipe_left_rounded,
                                    size: 18,
                                    color: appMutedTextColor,
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
            }),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  100 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: darkMode
                      ? Colors.black.withOpacity(0.80)
                      : Colors.white.withOpacity(0.88),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            style: TextStyle(color: appTextColor),
                            decoration: InputDecoration(
                              hintText: 'Cod promo',
                              hintStyle: TextStyle(color: appMutedTextColor),
                              filled: true,
                              fillColor: appSurfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: applyCoupon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Aplică'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                        Text(
                          '${cartTotal.toStringAsFixed(2)} Lei',
                          style: TextStyle(
                            color: appTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transport',
                          style: TextStyle(color: appMutedTextColor),
                        ),
                        Text(
                          shippingCost == 0
                              ? 'GRATUIT'
                              : '${shippingCost.toStringAsFixed(2)} Lei',
                          style: TextStyle(
                            color: shippingCost == 0
                                ? Colors.green
                                : appTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (discountValue > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reducere ($appliedCoupon)',
                            style: TextStyle(color: appMutedTextColor),
                          ),
                          Text(
                            '-${discountValue.toStringAsFixed(2)} Lei',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: appTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: finalTotal),
                          duration: const Duration(milliseconds: 500),
                          builder: (_, value, __) {
                            return Text(
                              '${value.toStringAsFixed(2)} Lei',
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                items: cart.values.toList(),
                                total: finalTotal,
                                onOrderDone: clearCart,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline),
                            SizedBox(width: 10),
                            Text(
                              'Finalizează comanda',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget quantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor),
      ),
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
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: productPriceBlock(product, priceSize: 15, oldPriceSize: 11),
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
  final Color backgroundColor;

  StickySearchHeaderDelegate({
    required this.height,
    required this.child,
    this.backgroundColor = const Color(0xFFF5F5F5),
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchHeaderDelegate oldDelegate) {
    return height != oldDelegate.height ||
        child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
