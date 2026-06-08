import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_service.dart';

class MyOrdersPage extends StatefulWidget {
  final Future<void> Function(List<dynamic> items)? onReorder;

  const MyOrdersPage({
    super.key,
    this.onReorder,
  });

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<List<dynamic>> ordersFuture;
  String? reorderingOrderNumber;

  @override
  void initState() {
    super.initState();
    ordersFuture = ApiService.fetchOrders();
  }

  Future<void> refreshOrders() async {
    setState(() {
      ordersFuture = ApiService.fetchOrders();
    });

    await ordersFuture;
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Dată indisponibilă';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    final local = parsed.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    final day = twoDigits(local.day);
    final month = twoDigits(local.month);
    final year = local.year;
    final hour = twoDigits(local.hour);
    final minute = twoDigits(local.minute);

    return '$day.$month.$year, $hour:$minute';
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return '${amount.toStringAsFixed(2)} Lei';
  }

  Color statusColor(String status) {
    final text = status.toLowerCase();

    if (text.contains('livrat')) return Colors.green;
    if (text.contains('anulat')) return Colors.red;
    if (text.contains('proces')) return Colors.blue;
    if (text.contains('merchantpro')) return Colors.orange;

    return primaryColor;
  }

  IconData statusIcon(String status) {
    final text = status.toLowerCase();

    if (text.contains('livrat')) return Icons.check_circle_outline;
    if (text.contains('anulat')) return Icons.cancel_outlined;
    if (text.contains('proces')) return Icons.sync_rounded;
    if (text.contains('merchantpro')) return Icons.cloud_done_outlined;

    return Icons.receipt_long_outlined;
  }

  List<dynamic> orderItems(dynamic order) {
    final items = order['items'];

    if (items is List) {
      return items;
    }

    return [];
  }

  Future<void> reorder(dynamic order) async {
    final callback = widget.onReorder;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recomandarea nu este disponibilă momentan.')),
      );
      return;
    }

    final items = orderItems(order);
    final orderNumber = order['order_number']?.toString() ?? '';

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda nu are produse salvate.')),
      );
      return;
    }

    setState(() {
      reorderingOrderNumber = orderNumber;
    });

    try {
      await callback(items);
    } finally {
      if (!mounted) return;

      setState(() {
        reorderingOrderNumber = null;
      });
    }
  }
Future<void> cancelOrder(dynamic order) async {
  final reasons = [
    'M-am răzgândit',
    'Am greșit produsele',
    'Am greșit adresa',
    'Nu mai am bani',
    'Am plasat comanda din greșeală',
    'Livrarea durează prea mult',
    'Alt motiv',
  ];

  String? selectedReason;
  final customReasonController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Anulează comanda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...reasons.map(
                    (reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedReason = value!;
                        });
                      },
                    ),
                  ),
                  if (selectedReason == 'Alt motiv')
                    TextField(
                      controller: customReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Scrie motivul',
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Renunță'),
              ),
              ElevatedButton(
                onPressed: () {

  if (selectedReason == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selectează un motiv.'),
      ),
    );
    return;
  }

  if (selectedReason == 'Alt motiv' &&
      customReasonController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scrie motivul anulării.'),
      ),
    );
    return;
  }

  Navigator.pop(dialogContext, true);
},
                child: const Text('Anulează'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) {
    customReasonController.dispose();
    return;
  }

  final customReason = customReasonController.text.trim();
  customReasonController.dispose();

  try {
    await ApiService.cancelOrder(
      order['id'].toString(),
      reason: selectedReason!,
      customReason: customReason,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comanda a fost anulată.'),
      ),
    );

    await refreshOrders();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.isEmpty ? 'Status indisponibil' : status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return RefreshIndicator(
      onRefresh: refreshOrders,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 110),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 58,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nu ai comenzi încă',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'După ce finalizezi o comandă, o vei vedea aici cu status, produse și total.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget errorState(Object error) {
    return RefreshIndicator(
      onRefresh: refreshOrders,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 110),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 58,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nu am putut încărca comenzile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Încearcă din nou'),
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

  Widget productRow(dynamic item) {
    final title = item['title']?.toString() ?? 'Produs';
    final quantity = item['quantity']?.toString() ?? '1';
    final price = item['price']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (price.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget orderCard(dynamic order) {
    final orderNumber = order['order_number']?.toString() ?? 'Comandă';
    final status = order['status']?.toString() ?? '';
    final total = formatMoney(order['total']);
    final createdAt = formatDate(order['created_at']);
    final items = orderItems(order);
    final deliveryMethod = order['delivery_method']?.toString() ?? '';
    final paymentMethod = order['payment_method']?.toString() ?? '';
    final totalValue =
    double.tryParse(order['total']?.toString() ?? '0') ?? 0;

final shippingAmount =
    deliveryMethod == 'Curier rapid' && totalValue < 400
        ? 24.90
        : 0.0;

final productsSubtotal = totalValue - shippingAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statusBadge(status),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        createdAt,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const SizedBox(height: 4),
            if (items.isEmpty)
              Text(
                'Nu există produse salvate pentru această comandă.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else ...[
              const Text(
                'Produse comandate',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...items.map(productRow).toList(),
            ],
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (deliveryMethod.isNotEmpty)
                    infoLine(
                      icon: Icons.local_shipping_outlined,
                      label: 'Livrare',
                      value: deliveryMethod,
                    ),
                  if (paymentMethod.isNotEmpty)
                    infoLine(
                      icon: Icons.payments_outlined,
                      label: 'Plată',
                      value: paymentMethod,
                    ),
                  infoLine(
  icon: Icons.shopping_bag_outlined,
  label: 'Subtotal produse',
  value: formatMoney(productsSubtotal),
),

infoLine(
  icon: Icons.local_shipping_outlined,
  label: 'Transport',
  value: formatMoney(shippingAmount),
),

infoLine(
  icon: Icons.receipt_long_outlined,
  label: 'Total',
  value: total,
  strong: true,
),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: reorderingOrderNumber == orderNumber
                    ? null
                    : () => reorder(order),
                icon: reorderingOrderNumber == orderNumber
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(
                  reorderingOrderNumber == orderNumber
                      ? 'Se adaugă în coș...'
                      : 'Comandă din nou',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withOpacity(0.55),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
           if (!status.toLowerCase().contains('anulat')) ...[
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: () => cancelOrder(order),
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Anulează comanda'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
  ),
],
          ],
        ),
      ),
    );
  }

  Widget infoLine({
    required IconData icon,
    required String label,
    required String value,
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: strong ? primaryColor : Colors.black87,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget ordersList(List<dynamic> orders) {
    return RefreshIndicator(
      onRefresh: refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: orders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${orders.length} ${orders.length == 1 ? 'comandă' : 'comenzi'} în contul tău',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return orderCard(orders[index - 1]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Comenzile mele'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return errorState(snapshot.error!);
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return emptyState();
          }

          return ordersList(orders);
        },
      ),
    );
  }
}
