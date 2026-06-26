import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading = true;
  bool saving = false;
  String customerType = 'individual';
  bool shippingSameAsBilling = true;

  Map<String, List<String>> romanianCities = {};
  String? selectedBillingCounty;
  String? selectedBillingCity;
  String? selectedShippingCounty;
  String? selectedShippingCity;

  final billingNameController = TextEditingController();
  final billingEmailController = TextEditingController();
  final billingPhoneController = TextEditingController();
  final billingAddressController = TextEditingController();
  final billingCityController = TextEditingController();
  final billingCountyController = TextEditingController();
  final billingPostalCodeController = TextEditingController();

  final companyNameController = TextEditingController();
  final companyCuiController = TextEditingController();
  final companyRegComController = TextEditingController();
  final companyIbanController = TextEditingController();
  final companyBankController = TextEditingController();
  final companyContactPersonController = TextEditingController();

  final shippingNameController = TextEditingController();
  final shippingEmailController = TextEditingController();
  final shippingPhoneController = TextEditingController();
  final shippingAddressController = TextEditingController();
  final shippingCityController = TextEditingController();
  final shippingCountyController = TextEditingController();
  final shippingPostalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    billingNameController.dispose();
    billingEmailController.dispose();
    billingPhoneController.dispose();
    billingAddressController.dispose();
    billingCityController.dispose();
    billingCountyController.dispose();
    billingPostalCodeController.dispose();

    companyNameController.dispose();
    companyCuiController.dispose();
    companyRegComController.dispose();
    companyIbanController.dispose();
    companyBankController.dispose();
    companyContactPersonController.dispose();

    shippingNameController.dispose();
    shippingEmailController.dispose();
    shippingPhoneController.dispose();
    shippingAddressController.dispose();
    shippingCityController.dispose();
    shippingCountyController.dispose();
    shippingPostalCodeController.dispose();

    super.dispose();
  }

  Future<void> loadInitialData() async {
    await loadRomaniaLocations();
    await loadProfile();
  }

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

  String textValue(dynamic value) => (value ?? '').toString();

  void setText(TextEditingController controller, dynamic value) {
    controller.text = textValue(value);
  }

  bool setLocation({
    required String county,
    required String city,
    required bool shipping,
  }) {
    final cleanCounty = county.trim();
    final cleanCity = city.trim();

    if (cleanCounty.isEmpty || !romanianCities.containsKey(cleanCounty)) {
      return false;
    }

    final cities = romanianCities[cleanCounty] ?? <String>[];
    final safeCity =
        cleanCity.isNotEmpty && cities.contains(cleanCity) ? cleanCity : null;

    if (shipping) {
      selectedShippingCounty = cleanCounty;
      selectedShippingCity = safeCity;
      shippingCountyController.text = cleanCounty;
      shippingCityController.text = safeCity ?? '';
    } else {
      selectedBillingCounty = cleanCounty;
      selectedBillingCity = safeCity;
      billingCountyController.text = cleanCounty;
      billingCityController.text = safeCity ?? '';
    }

    return true;
  }

  Future<void> loadProfile() async {
    try {
      final response = await ApiService.getProfile();
      final data = Map<String, dynamic>.from(response['data'] ?? {});

      if (!mounted) return;

      setState(() {
        customerType = textValue(data['customer_type']).isEmpty
            ? 'individual'
            : textValue(data['customer_type']);

        shippingSameAsBilling = data['shipping_same_as_billing'] != false;

        setText(billingNameController, data['billing_name'] ?? data['name']);
        setText(billingEmailController, data['billing_email'] ?? data['email']);
        setText(billingPhoneController, data['billing_phone']);
        setText(billingAddressController, data['billing_address']);
        setText(billingPostalCodeController, data['billing_postal_code']);

        setLocation(
          county: textValue(data['billing_county']),
          city: textValue(data['billing_city']),
          shipping: false,
        );

        setText(companyNameController, data['company_name']);
        setText(companyCuiController, data['company_cui']);
        setText(companyRegComController, data['company_reg_com']);
        setText(companyIbanController, data['company_iban']);
        setText(companyBankController, data['company_bank']);
        setText(companyContactPersonController, data['company_contact_person']);

        setText(shippingNameController, data['shipping_name']);
        setText(shippingEmailController, data['shipping_email']);
        setText(shippingPhoneController, data['shipping_phone']);
        setText(shippingAddressController, data['shipping_address']);
        setText(shippingPostalCodeController, data['shipping_postal_code']);

        setLocation(
          county: textValue(data['shipping_county']),
          city: textValue(data['shipping_city']),
          shipping: true,
        );

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut încărca profilul: $error')),
      );
    }
  }

  Future<void> saveProfile() async {
    FocusScope.of(context).unfocus();

    setState(() {
      saving = true;
    });

    final billingCounty =
        selectedBillingCounty ?? billingCountyController.text.trim();

    final billingCity =
        selectedBillingCity ?? billingCityController.text.trim();

    final shippingName = shippingSameAsBilling
        ? billingNameController.text.trim()
        : shippingNameController.text.trim();

    final shippingEmail = shippingSameAsBilling
        ? billingEmailController.text.trim()
        : shippingEmailController.text.trim();

    final shippingPhone = shippingSameAsBilling
        ? billingPhoneController.text.trim()
        : shippingPhoneController.text.trim();

    final shippingAddress = shippingSameAsBilling
        ? billingAddressController.text.trim()
        : shippingAddressController.text.trim();

    final shippingCounty = shippingSameAsBilling
        ? billingCounty
        : (selectedShippingCounty ?? shippingCountyController.text.trim());

    final shippingCity = shippingSameAsBilling
        ? billingCity
        : (selectedShippingCity ?? shippingCityController.text.trim());

    final shippingPostalCode = shippingSameAsBilling
        ? billingPostalCodeController.text.trim()
        : shippingPostalCodeController.text.trim();

    final profile = {
      'customer_type': customerType,

      'billing_name': billingNameController.text.trim(),
      'billing_email': billingEmailController.text.trim(),
      'billing_phone': billingPhoneController.text.trim(),
      'billing_address': billingAddressController.text.trim(),
      'billing_city': billingCity,
      'billing_county': billingCounty,
      'billing_postal_code': billingPostalCodeController.text.trim(),

      'company_name':
          customerType == 'company' ? companyNameController.text.trim() : '',
      'company_cui':
          customerType == 'company' ? companyCuiController.text.trim() : '',
      'company_reg_com':
          customerType == 'company' ? companyRegComController.text.trim() : '',
      'company_iban':
          customerType == 'company' ? companyIbanController.text.trim() : '',
      'company_bank':
          customerType == 'company' ? companyBankController.text.trim() : '',
      'company_contact_person': customerType == 'company'
          ? companyContactPersonController.text.trim()
          : '',

      'shipping_same_as_billing': shippingSameAsBilling,
      'shipping_name': shippingName,
      'shipping_email': shippingEmail,
      'shipping_phone': shippingPhone,
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'shipping_county': shippingCounty,
      'shipping_postal_code': shippingPostalCode,
    };

    try {
      await ApiService.saveProfile(profile: profile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil salvat cu succes.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut salva profilul: $error')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  InputDecoration fieldDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1B20) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade300;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      prefixIcon: Icon(icon, color: mutedColor),
      filled: true,
      fillColor: surfaceColor,
      hintStyle: TextStyle(color: mutedColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        decoration: fieldDecoration(context, label, icon),
      ),
    );
  }

  Widget countyDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final counties = romanianCities.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value != null && counties.contains(value) ? value : null,
        isExpanded: true,
        dropdownColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B20)
            : Colors.white,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        decoration: fieldDecoration(context, label, Icons.map_outlined),
        items: counties
            .map(
              (county) => DropdownMenuItem(
                value: county,
                child: Text(county),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget cityDropdown({
    required String label,
    required String? county,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final cities = county == null ? <String>[] : romanianCities[county] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value != null && cities.contains(value) ? value : null,
        isExpanded: true,
        dropdownColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B20)
            : Colors.white,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        decoration: fieldDecoration(context, label, Icons.location_city_outlined),
        items: cities
            .map(
              (city) => DropdownMenuItem(
                value: city,
                child: Text(
                  city,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: county == null ? null : onChanged,
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B1B20) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget customerTypeSelector() {
    return sectionCard(
      title: 'Tip client',
      icon: Icons.person_outline,
      children: [
        RadioListTile<String>(
          value: 'individual',
          groupValue: customerType,
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
          title: Text('Persoană fizică', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              customerType = value;
            });
          },
        ),
        RadioListTile<String>(
          value: 'company',
          groupValue: customerType,
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
          title: Text('Persoană juridică', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              customerType = value;
            });
          },
        ),
      ],
    );
  }

  Widget individualBillingFields() {
    return sectionCard(
      title: 'Date facturare',
      icon: Icons.receipt_long_outlined,
      children: [
        field(
          controller: billingNameController,
          label: 'Nume și prenume',
          icon: Icons.person_outline,
        ),
        commonBillingFields(),
      ],
    );
  }

  Widget companyBillingFields() {
    return sectionCard(
      title: 'Date firmă',
      icon: Icons.business_outlined,
      children: [
        field(
          controller: companyNameController,
          label: 'Firmă',
          icon: Icons.business_outlined,
        ),
        field(
          controller: companyCuiController,
          label: 'CIF/CUI',
          icon: Icons.confirmation_number_outlined,
        ),
        field(
          controller: companyRegComController,
          label: 'Nr. Reg. Com.',
          icon: Icons.assignment_outlined,
        ),
        field(
          controller: companyIbanController,
          label: 'IBAN',
          icon: Icons.account_balance_wallet_outlined,
        ),
        field(
          controller: companyBankController,
          label: 'Bancă',
          icon: Icons.account_balance_outlined,
        ),
        field(
          controller: companyContactPersonController,
          label: 'Persoană contact',
          icon: Icons.contact_phone_outlined,
        ),
        field(
          controller: billingNameController,
          label: 'Nume pentru facturare',
          icon: Icons.person_outline,
        ),
        commonBillingFields(),
      ],
    );
  }

  Widget commonBillingFields() {
    return Column(
      children: [
        field(
          controller: billingEmailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        field(
          controller: billingPhoneController,
          label: 'Telefon',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        field(
          controller: billingAddressController,
          label: 'Adresă',
          icon: Icons.home_outlined,
        ),
        countyDropdown(
          label: 'Județ',
          value: selectedBillingCounty,
          onChanged: (value) {
            setState(() {
              selectedBillingCounty = value;
              selectedBillingCity = null;
              billingCountyController.text = value ?? '';
              billingCityController.clear();
            });
          },
        ),
        cityDropdown(
          label: 'Oraș / Localitate',
          county: selectedBillingCounty,
          value: selectedBillingCity,
          onChanged: (value) {
            setState(() {
              selectedBillingCity = value;
              billingCityController.text = value ?? '';
            });
          },
        ),
        field(
          controller: billingPostalCodeController,
          label: 'Cod poștal',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget shippingFields() {
    return sectionCard(
      title: 'Date livrare',
      icon: Icons.local_shipping_outlined,
      children: [
        SwitchListTile(
          value: shippingSameAsBilling,
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Datele de livrare sunt identice cu cele de facturare',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          onChanged: (value) {
            setState(() {
              shippingSameAsBilling = value;
            });
          },
        ),
        if (!shippingSameAsBilling) ...[
          const SizedBox(height: 12),
          field(
            controller: shippingNameController,
            label: 'Nume destinatar',
            icon: Icons.person_outline,
          ),
          field(
            controller: shippingEmailController,
            label: 'Email livrare',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          field(
            controller: shippingPhoneController,
            label: 'Telefon livrare',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          field(
            controller: shippingAddressController,
            label: 'Adresă livrare',
            icon: Icons.home_outlined,
          ),
          countyDropdown(
            label: 'Județ livrare',
            value: selectedShippingCounty,
            onChanged: (value) {
              setState(() {
                selectedShippingCounty = value;
                selectedShippingCity = null;
                shippingCountyController.text = value ?? '';
                shippingCityController.clear();
              });
            },
          ),
          cityDropdown(
            label: 'Oraș / Localitate livrare',
            county: selectedShippingCounty,
            value: selectedShippingCity,
            onChanged: (value) {
              setState(() {
                selectedShippingCity = value;
                shippingCityController.text = value ?? '';
              });
            },
          ),
          field(
            controller: shippingPostalCodeController,
            label: 'Cod poștal livrare',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF5F5F5);
    final surfaceColor = isDark ? const Color(0xFF1B1B20) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profilul meu'),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                130 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                customerTypeSelector(),
                customerType == 'company'
                    ? companyBillingFields()
                    : individualBillingFields(),
                shippingFields(),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: surfaceColor,
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : saveProfile,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Se salvează...' : 'Salvează profilul'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
