import 'package:flutter/material.dart';

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
    loadProfile();
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

  String textValue(dynamic value) => (value ?? '').toString();

  void setText(TextEditingController controller, dynamic value) {
    controller.text = textValue(value);
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
        setText(billingCityController, data['billing_city']);
        setText(billingCountyController, data['billing_county']);
        setText(billingPostalCodeController, data['billing_postal_code']);

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
        setText(shippingCityController, data['shipping_city']);
        setText(shippingCountyController, data['shipping_county']);
        setText(shippingPostalCodeController, data['shipping_postal_code']);

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

    final shippingCity = shippingSameAsBilling
        ? billingCityController.text.trim()
        : shippingCityController.text.trim();

    final shippingCounty = shippingSameAsBilling
        ? billingCountyController.text.trim()
        : shippingCountyController.text.trim();

    final shippingPostalCode = shippingSameAsBilling
        ? billingPostalCodeController.text.trim()
        : shippingPostalCodeController.text.trim();

    final profile = {
      'customer_type': customerType,

      'billing_name': billingNameController.text.trim(),
      'billing_email': billingEmailController.text.trim(),
      'billing_phone': billingPhoneController.text.trim(),
      'billing_address': billingAddressController.text.trim(),
      'billing_city': billingCityController.text.trim(),
      'billing_county': billingCountyController.text.trim(),
      'billing_postal_code': billingPostalCodeController.text.trim(),

      'company_name': customerType == 'company'
          ? companyNameController.text.trim()
          : '',
      'company_cui': customerType == 'company'
          ? companyCuiController.text.trim()
          : '',
      'company_reg_com': customerType == 'company'
          ? companyRegComController.text.trim()
          : '',
      'company_iban': customerType == 'company'
          ? companyIbanController.text.trim()
          : '',
      'company_bank': customerType == 'company'
          ? companyBankController.text.trim()
          : '',
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

  InputDecoration fieldDecoration(String label, IconData icon) {
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
        decoration: fieldDecoration(label, icon),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
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
                  style: const TextStyle(
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
          title: const Text('Persoană fizică'),
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
          title: const Text('Persoană juridică'),
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
        field(
          controller: billingCityController,
          label: 'Oraș',
          icon: Icons.location_city_outlined,
        ),
        field(
          controller: billingCountyController,
          label: 'Județ',
          icon: Icons.map_outlined,
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
          title: const Text(
            'Datele de livrare sunt identice cu cele de facturare',
            style: TextStyle(fontWeight: FontWeight.w600),
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
          field(
            controller: shippingCityController,
            label: 'Oraș livrare',
            icon: Icons.location_city_outlined,
          ),
          field(
            controller: shippingCountyController,
            label: 'Județ livrare',
            icon: Icons.map_outlined,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profilul meu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                110 + MediaQuery.of(context).padding.bottom,
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
          color: Colors.white,
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
