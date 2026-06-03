import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<dynamic>> usersFuture;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    usersFuture = ApiService.fetchAdminUsers();
  }

  Future<void> refreshUsers() async {
    setState(() {
      usersFuture = ApiService.fetchAdminUsers();
    });

    await usersFuture;
  }

  String textValue(dynamic value) => value?.toString() ?? '';

  List<Map<String, dynamic>> normalizeUsers(List<dynamic> users) {
    return users
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> filteredUsers(List<Map<String, dynamic>> users) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return users;

    return users.where((user) {
      final name = textValue(user['name']).toLowerCase();
      final email = textValue(user['email']).toLowerCase();
      final phone = textValue(user['billing_phone']).toLowerCase();
      final company = textValue(user['company_name']).toLowerCase();
      final cui = textValue(user['company_cui']).toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          company.contains(query) ||
          cui.contains(query);
    }).toList();
  }

  String formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);

    if (date == null) return raw;

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> openEditUser(Map<String, dynamic> user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserEditPage(user: user),
      ),
    );

    if (updated == true) {
      await refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin clienți'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: refreshUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reîncarcă',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Eroare: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final users = normalizeUsers(snapshot.data ?? []);
          final visibleUsers = filteredUsers(users);
          final adminCount =
              users.where((user) => textValue(user['role']) == 'admin').length;

          return RefreshIndicator(
            onRefresh: refreshUsers,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Clienți',
                        value: users.length.toString(),
                        icon: Icons.people_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Admini',
                        value: adminCount.toString(),
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Caută după nume, email, telefon, firmă...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (visibleUsers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('Nu există clienți')),
                  )
                else
                  ...visibleUsers.map(
                    (user) => AdminUserCard(
                      user: user,
                      onEdit: () => openEditUser(user),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onEdit,
  });

  String textValue(dynamic value) => value?.toString() ?? '';

  String formatCustomerType(String value) {
    if (value == 'company') return 'Persoană juridică';
    return 'Persoană fizică';
  }

  String formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);

    if (date == null) return raw;

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final role = textValue(user['role']).isEmpty ? 'user' : textValue(user['role']);
    final customerType = textValue(user['customer_type']).isEmpty
        ? 'individual'
        : textValue(user['customer_type']);

    final isAdmin = role == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? Colors.black
              : primaryColor.withOpacity(0.12),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            color: isAdmin ? Colors.white : primaryColor,
          ),
        ),
        title: Text(
          textValue(user['name']).isEmpty
              ? 'Client fără nume'
              : textValue(user['name']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(textValue(user['email'])),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniBadge(
                    label: isAdmin ? 'Admin' : 'User',
                    color: isAdmin ? Colors.black : primaryColor,
                  ),
                  _MiniBadge(
                    label: formatCustomerType(customerType),
                    color: customerType == 'company'
                        ? Colors.deepPurple
                        : Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          _InfoRow(label: 'Telefon', value: textValue(user['billing_phone'])),
          _InfoRow(label: 'Tip client', value: formatCustomerType(customerType)),
          _InfoRow(label: 'Rol', value: role),
          _InfoRow(label: 'Creat la', value: formatDate(user['created_at'])),
          if (customerType == 'company') ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Date firmă',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            _InfoRow(label: 'Firmă', value: textValue(user['company_name'])),
            _InfoRow(label: 'CUI', value: textValue(user['company_cui'])),
            _InfoRow(
              label: 'Reg. Com.',
              value: textValue(user['company_reg_com']),
            ),
          ],
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Facturare',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          _InfoRow(label: 'Nume', value: textValue(user['billing_name'])),
          _InfoRow(label: 'Email', value: textValue(user['billing_email'])),
          _InfoRow(
            label: 'Adresă',
            value:
                '${textValue(user['billing_address'])}, ${textValue(user['billing_city'])}, ${textValue(user['billing_county'])}',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editează client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUserEditPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserEditPage({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserEditPage> createState() => _AdminUserEditPageState();
}

class _AdminUserEditPageState extends State<AdminUserEditPage> {
  bool saving = false;
  late String role;
  late String customerType;
  late bool shippingSameAsBilling;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

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
    final user = widget.user;

    role = textValue(user['role']).isEmpty ? 'user' : textValue(user['role']);
    customerType = textValue(user['customer_type']).isEmpty
        ? 'individual'
        : textValue(user['customer_type']);
    shippingSameAsBilling = user['shipping_same_as_billing'] != false;

    nameController.text = textValue(user['name']);
    emailController.text = textValue(user['email']);

    billingNameController.text = textValue(user['billing_name']);
    billingEmailController.text = textValue(user['billing_email']);
    billingPhoneController.text = textValue(user['billing_phone']);
    billingAddressController.text = textValue(user['billing_address']);
    billingCityController.text = textValue(user['billing_city']);
    billingCountyController.text = textValue(user['billing_county']);
    billingPostalCodeController.text = textValue(user['billing_postal_code']);

    companyNameController.text = textValue(user['company_name']);
    companyCuiController.text = textValue(user['company_cui']);
    companyRegComController.text = textValue(user['company_reg_com']);
    companyIbanController.text = textValue(user['company_iban']);
    companyBankController.text = textValue(user['company_bank']);
    companyContactPersonController.text =
        textValue(user['company_contact_person']);

    shippingNameController.text = textValue(user['shipping_name']);
    shippingEmailController.text = textValue(user['shipping_email']);
    shippingPhoneController.text = textValue(user['shipping_phone']);
    shippingAddressController.text = textValue(user['shipping_address']);
    shippingCityController.text = textValue(user['shipping_city']);
    shippingCountyController.text = textValue(user['shipping_county']);
    shippingPostalCodeController.text =
        textValue(user['shipping_postal_code']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();

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

  String textValue(dynamic value) => value?.toString() ?? '';

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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Future<void> saveUser() async {
    FocusScope.of(context).unfocus();

    setState(() {
      saving = true;
    });

    final userData = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'role': role,
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
      'shipping_name': shippingSameAsBilling
          ? billingNameController.text.trim()
          : shippingNameController.text.trim(),
      'shipping_email': shippingSameAsBilling
          ? billingEmailController.text.trim()
          : shippingEmailController.text.trim(),
      'shipping_phone': shippingSameAsBilling
          ? billingPhoneController.text.trim()
          : shippingPhoneController.text.trim(),
      'shipping_address': shippingSameAsBilling
          ? billingAddressController.text.trim()
          : shippingAddressController.text.trim(),
      'shipping_city': shippingSameAsBilling
          ? billingCityController.text.trim()
          : shippingCityController.text.trim(),
      'shipping_county': shippingSameAsBilling
          ? billingCountyController.text.trim()
          : shippingCountyController.text.trim(),
      'shipping_postal_code': shippingSameAsBilling
          ? billingPostalCodeController.text.trim()
          : shippingPostalCodeController.text.trim(),
    };

    try {
      await ApiService.updateAdminUser(
        userId: widget.user['id'].toString(),
        userData: userData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client actualizat.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut salva clientul: $error')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Widget accountSection() {
    return sectionCard(
      title: 'Cont',
      icon: Icons.account_circle_outlined,
      children: [
        field(
          controller: nameController,
          label: 'Nume cont',
          icon: Icons.person_outline,
        ),
        field(
          controller: emailController,
          label: 'Email cont',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: role,
            decoration: fieldDecoration('Rol', Icons.admin_panel_settings),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                role = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget typeSection() {
    return sectionCard(
      title: 'Tip client',
      icon: Icons.badge_outlined,
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

  Widget billingSection() {
    return sectionCard(
      title: customerType == 'company' ? 'Facturare firmă' : 'Facturare',
      icon: Icons.receipt_long_outlined,
      children: [
        if (customerType == 'company') ...[
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
        ],
        field(
          controller: billingNameController,
          label: 'Nume facturare',
          icon: Icons.person_outline,
        ),
        field(
          controller: billingEmailController,
          label: 'Email facturare',
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
          controller: billingCountyController,
          label: 'Județ',
          icon: Icons.map_outlined,
        ),
        field(
          controller: billingCityController,
          label: 'Oraș / Localitate',
          icon: Icons.location_city_outlined,
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

  Widget shippingSection() {
    return sectionCard(
      title: 'Livrare',
      icon: Icons.local_shipping_outlined,
      children: [
        SwitchListTile(
          value: shippingSameAsBilling,
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Livrare identică cu facturarea',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          onChanged: (value) {
            setState(() {
              shippingSameAsBilling = value;
            });
          },
        ),
        if (!shippingSameAsBilling) ...[
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
            controller: shippingCountyController,
            label: 'Județ livrare',
            icon: Icons.map_outlined,
          ),
          field(
            controller: shippingCityController,
            label: 'Oraș livrare',
            icon: Icons.location_city_outlined,
          ),
          field(
            controller: shippingPostalCodeController,
            label: 'Cod poștal livrare',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = textValue(widget.user['name']).isEmpty
        ? 'Editare client'
        : textValue(widget.user['name']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          110 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          accountSection(),
          typeSection(),
          billingSection(),
          shippingSection(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: Colors.white,
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: saving ? null : saveUser,
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
              label: Text(saving ? 'Se salvează...' : 'Salvează clientul'),
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

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty || value.trim() == ', ,') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
