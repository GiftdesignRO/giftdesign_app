import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../services/api_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<Map<String, dynamic>>> ordersFuture;
  String searchQuery = '';
  bool syncingMerchantPro = false;

  static const String ordersUrl = '$apiBaseUrl/admin/orders';
  static const String syncMerchantProUrl =
      '$apiBaseUrl/admin/orders/sync-merchantpro';

  @override
  void initState() {
    super.initState();
    ordersFuture = fetchOrders();
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await http.get(
      Uri.parse(ordersUrl),
      headers: await ApiService.authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] ?? 'Nu am putut încărca comenzile.',
      );
    }

    final List data = decoded['data'] ?? [];

    return data.whereType<Map<String, dynamic>>().toList().toList();
  }

  Future<void> refreshOrders() async {
    setState(() {
      ordersFuture = fetchOrders();
    });

    await ordersFuture;
  }

  Future<void> syncMerchantProOrders() async {
    if (syncingMerchantPro) return;

    setState(() {
      syncingMerchantPro = true;
    });

    try {
      final response = await http.post(
        Uri.parse(syncMerchantProUrl),
        headers: await ApiService.authHeaders(),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded['error']?.toString() ??
                  'Sincronizarea MerchantPro a eșuat.',
            ),
          ),
        );
        return;
      }

      final imported = decoded['imported']?.toString() ?? '0';
      final skipped = decoded['skipped']?.toString() ?? '0';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'MerchantPro sincronizat: $imported importate, $skipped existente.',
          ),
        ),
      );

      await refreshOrders();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare sincronizare: $error')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        syncingMerchantPro = false;
      });
    }
  }

  String textValue(dynamic value) {
    return value?.toString() ?? '';
  }

  String formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);

    if (date == null) return raw;

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  double readTotal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> filteredOrders(List<Map<String, dynamic>> orders) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return orders;

    return orders.where((order) {
      final customer = order['customer'] is Map ? order['customer'] as Map : {};
      final orderNumber = textValue(order['order_number']).toLowerCase();
      final name = textValue(customer['name']).toLowerCase();
      final email = textValue(customer['email']).toLowerCase();
      final phone = textValue(customer['phone']).toLowerCase();
      final status = textValue(order['status']).toLowerCase();

      return orderNumber.contains(query) ||
          name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          status.contains(query);
    }).toList();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nouă':
      case 'noua':
        return primaryColor;
      case 'procesare':
        return Colors.orange;
      case 'livrată':
      case 'livrata':
        return Colors.green;
      case 'anulată':
      case 'anulata':
        return Colors.grey;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin comenzi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
  IconButton(
    onPressed: syncingMerchantPro ? null : syncMerchantProOrders,
    icon: syncingMerchantPro
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.sync),
    tooltip: 'Sincronizează MerchantPro',
  ),
  IconButton(
    onPressed: refreshOrders,
    icon: const Icon(Icons.refresh),
    tooltip: 'Reîncarcă',
  ),
],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          final orders = snapshot.data ?? [];
          final visibleOrders = filteredOrders(orders);
          final totalSales = orders.fold<double>(
            0,
            (sum, order) => sum + readTotal(order['total']),
          );

          return RefreshIndicator(
            onRefresh: refreshOrders,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Comenzi',
                        value: orders.length.toString(),
                        icon: Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total',
                        value: '${totalSales.toStringAsFixed(2)} Lei',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                SizedBox(
  height: 48,
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: syncingMerchantPro ? null : syncMerchantProOrders,
    icon: syncingMerchantPro
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.sync),
    label: Text(
      syncingMerchantPro
          ? 'Se sincronizează cu MerchantPro...'
          : 'Sincronizează cu MerchantPro',
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
const SizedBox(height: 14),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Caută după număr, client, email, telefon...',
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
                if (visibleOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('Nu există comenzi')),
                  )
                else
                  ...visibleOrders.map((order) => OrderAdminCard(order: order)),
              ],
            ),
          );
        },
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

class OrderAdminCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderAdminCard({super.key, required this.order});

  String textValue(dynamic value) => value?.toString() ?? '';

  double readTotal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);

    if (date == null) return raw;

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nouă':
      case 'noua':
        return primaryColor;
      case 'procesare':
        return Colors.orange;
      case 'livrată':
      case 'livrata':
        return Colors.green;
      case 'anulată':
      case 'anulata':
        return Colors.grey;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'] is Map ? order['customer'] as Map : {};
    final items = order['items'] is List ? order['items'] as List : [];
    final orderNumber = textValue(order['order_number']).isNotEmpty
        ? textValue(order['order_number'])
        : textValue(order['id']);
    final status = textValue(order['status']).isNotEmpty
        ? textValue(order['status'])
        : 'Nouă';
        final cancelReason = textValue(order['cancel_reason']);
        final cancelledAt = textValue(order['cancelled_at']);
        final cancelledBy = textValue(order['cancelled_by']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Expanded(
              child: Text(
                orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textValue(customer['name']).isEmpty
                    ? 'Client fără nume'
                    : textValue(customer['name']),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(formatDate(order['created_at'])),
              const SizedBox(height: 4),
              Text(
                '${readTotal(order['total']).toStringAsFixed(2)} Lei',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          _InfoRow(label: 'Email', value: textValue(customer['email'])),
          _InfoRow(label: 'Telefon', value: textValue(customer['phone'])),
          _InfoRow(
            label: 'Adresă',
            value:
                '${textValue(customer['address'])}, ${textValue(customer['city'])}, ${textValue(customer['county'])}',
          ),
          _InfoRow(
            label: 'Livrare',
            value: textValue(order['delivery_method']),
          ),
          _InfoRow(label: 'Plată', value: textValue(order['payment_method'])),
          if (cancelReason.isNotEmpty) ...[
  const SizedBox(height: 10),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.red.withOpacity(0.20),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalii anulare',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          label: 'Motiv',
          value: cancelReason,
        ),
        _InfoRow(
          label: 'Anulată la',
          value: formatDate(cancelledAt),
        ),
        _InfoRow(
          label: 'De',
          value: cancelledBy,
        ),
      ],
    ),
  ),
],
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Produse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final map = item is Map ? item : {};
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      textValue(map['title']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${textValue(map['quantity'])} x ${textValue(map['price'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
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
