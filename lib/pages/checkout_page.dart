import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

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
  @override
  void initState() {
    super.initState();
    loadCheckoutData();
  }

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  String? selectedCounty;
  String? selectedCity;
  String deliveryMethod = 'Curier rapid';
  String paymentMethod = 'Ramburs';
  bool profileLoading = true;
  Future<void> loadRomaniaLocations() async {
  try {
    final raw = await rootBundle.loadString(
      'assets/data/romania_locations.json',
    );

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    romanianCities = decoded.map((key, value) {
      final cities = (value as List)
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList()
        ..sort();

      return MapEntry(key.toString(), cities);
    });
  } catch (_) {
    romanianCities = {};
  }
}
  Future<void> loadCheckoutData() async {
    await loadRomaniaLocations();
    await loadSavedCheckoutData();
    await loadProfileCheckoutData();

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });
  }

  bool setCountyAndCity({
    required String county,
    required String city,
  }) {
    if (county.isEmpty || !romanianCities.containsKey(county)) {
      return false;
    }

    selectedCounty = county;

    final cityList = romanianCities[county] ?? <String>[];

    if (city.isNotEmpty && cityList.contains(city)) {
      selectedCity = city;
    } else {
      selectedCity = null;
    }

    return true;
  }

  Future<void> loadProfileCheckoutData() async {
    try {
      final response = await ApiService.getProfile();
      final data = Map<String, dynamic>.from(response['data'] ?? {});

      final sameAsBilling = data['shipping_same_as_billing'] != false;

      final profileName = sameAsBilling
          ? (data['billing_name'] ?? data['name'] ?? '').toString()
          : (data['shipping_name'] ?? data['billing_name'] ?? data['name'] ?? '')
              .toString();

      final profileEmail = sameAsBilling
          ? (data['billing_email'] ?? data['email'] ?? '').toString()
          : (data['shipping_email'] ??
                  data['billing_email'] ??
                  data['email'] ??
                  '')
              .toString();

      final profilePhone = sameAsBilling
          ? (data['billing_phone'] ?? '').toString()
          : (data['shipping_phone'] ?? data['billing_phone'] ?? '').toString();

      final profileAddress = sameAsBilling
          ? (data['billing_address'] ?? '').toString()
          : (data['shipping_address'] ?? data['billing_address'] ?? '')
              .toString();

      final profileCounty = sameAsBilling
          ? (data['billing_county'] ?? '').toString()
          : (data['shipping_county'] ?? data['billing_county'] ?? '').toString();

      final profileCity = sameAsBilling
          ? (data['billing_city'] ?? '').toString()
          : (data['shipping_city'] ?? data['billing_city'] ?? '').toString();

      if (profileName.trim().isNotEmpty) {
        nameController.text = profileName.trim();
      }

      if (profileEmail.trim().isNotEmpty) {
        emailController.text = profileEmail.trim();
      }

      if (profilePhone.trim().isNotEmpty) {
        phoneController.text = profilePhone.trim();
      }

      if (profileAddress.trim().isNotEmpty) {
        addressController.text = profileAddress.trim();
      }

      setCountyAndCity(
        county: profileCounty.trim(),
        city: profileCity.trim(),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Dacă profilul nu poate fi încărcat, checkout-ul rămâne funcțional
      // cu datele salvate local anterior.
    }
  }

  Future<void> loadSavedCheckoutData() async {
    final prefs = await SharedPreferences.getInstance();

    nameController.text =
        prefs.getString('checkout_name') ?? prefs.getString('user_name') ?? '';
    phoneController.text = prefs.getString('checkout_phone') ?? '';
    emailController.text =
        prefs.getString('checkout_email') ??
        prefs.getString('user_email') ??
        '';
    addressController.text = prefs.getString('checkout_address') ?? '';

    final savedCounty = prefs.getString('checkout_county');
    final savedCity = prefs.getString('checkout_city');

    if (savedCounty != null && savedCity != null) {
      setCountyAndCity(
        county: savedCounty,
        city: savedCity,
      );
    }

    final savedDeliveryMethod = prefs.getString('checkout_delivery_method');
    final savedPaymentMethod = prefs.getString('checkout_payment_method');

    if (savedDeliveryMethod != null && savedDeliveryMethod.isNotEmpty) {
      deliveryMethod = savedDeliveryMethod;
    }

    if (savedPaymentMethod != null && savedPaymentMethod.isNotEmpty) {
      paymentMethod = savedPaymentMethod;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveCheckoutData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('checkout_name', nameController.text.trim());
    await prefs.setString('checkout_phone', phoneController.text.trim());
    await prefs.setString('checkout_email', emailController.text.trim());
    await prefs.setString('checkout_address', addressController.text.trim());
    await prefs.setString('checkout_county', selectedCounty ?? '');
    await prefs.setString('checkout_city', selectedCity ?? '');
    await prefs.setString('checkout_delivery_method', deliveryMethod);
    await prefs.setString('checkout_payment_method', paymentMethod);
  }

  Map<String, List<String>> romanianCities = {};

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

  @override
  Widget build(BuildContext context) {
    final counties = romanianCities.keys.toList()..sort();
    final cities = selectedCounty == null
        ? <String>[]
        : romanianCities[selectedCounty] ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
  key: _formKey,
  child: ListView(
    padding: const EdgeInsets.fromLTRB(
      16,
      16,
      16,
      90,
    ),
          children: [
            const Text(
              'Date livrare',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (profileLoading) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Încărcăm datele din profil...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: nameController,
              decoration: fieldDecoration('Nume și prenume'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Completează numele'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration('Telefon'),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'Completează telefonul'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration('Email'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Email invalid'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCounty,
              decoration: fieldDecoration('Județ'),
              items: counties
                  .map(
                    (county) =>
                        DropdownMenuItem(value: county, child: Text(county)),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                selectedCounty = value;
                selectedCity = null;
              }),
              validator: (value) => value == null ? 'Alege județul' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: fieldDecoration('Oraș / Localitate'),
              items: cities
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  )
                  .toList(),
              onChanged: selectedCounty == null
                  ? null
                  : (value) => setState(() => selectedCity = value),
              validator: (value) => value == null ? 'Alege orașul' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              maxLines: 2,
              decoration: fieldDecoration('Adresă completă'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Completează adresa'
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Livrare',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
            const Text(
              'Plată',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                    const Text(
                      'Sumar comandă',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} x ${item.product.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${item.total.toStringAsFixed(2)} Lei'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.total.toStringAsFixed(2)} Lei',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  try {
                    await saveCheckoutData();

                    final response = await http.post(
  Uri.parse('$apiBaseUrl/orders'),
  headers: await ApiService.authHeaders(),
                      body: jsonEncode({
                        'customer': {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'email': emailController.text.trim(),
                          'county': selectedCounty,
                          'city': selectedCity,
                          'address': addressController.text.trim(),
                        },
                        'items': widget.items.map((item) {
                          return {
                            'title': item.product.title,
                            'price': item.product.price,
                            'quantity': item.quantity,
                            'sku': item.product.sku,
                          };
                        }).toList(),
                        'total': widget.total,
                        'delivery_method': deliveryMethod,
                        'payment_method': paymentMethod,
                      }),
                    );

                    if (!mounted) return;

                    if (response.statusCode == 201) {
                      final decoded = jsonDecode(response.body);
                      final orderNumber =
                          decoded['order_number']?.toString() ?? 'GD';

                      widget.onOrderDone();

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Comandă trimisă'),
                          content: Text(
                            'Comanda $orderNumber a fost salvată cu succes.',
                          ),
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comanda nu a putut fi trimisă.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare server: $e')),
                    );
                  }
                },
                child: const Text(
                  'Trimite comanda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
