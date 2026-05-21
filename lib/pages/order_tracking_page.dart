import 'package:flutter/material.dart';
import '../core/constants.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final trackingController = TextEditingController();
  String searchedCode = '';
  bool searched = false;

  final List<_TrackingStep> demoSteps = const [
    _TrackingStep(
      title: 'Comandă plasată',
      subtitle: 'Am primit comanda ta în sistem.',
      icon: Icons.receipt_long_outlined,
      done: true,
    ),
    _TrackingStep(
      title: 'Confirmată',
      subtitle: 'Comanda este confirmată și pregătită pentru procesare.',
      icon: Icons.verified_outlined,
      done: true,
    ),
    _TrackingStep(
      title: 'În pregătire',
      subtitle: 'Produsele sunt verificate și ambalate.',
      icon: Icons.inventory_2_outlined,
      done: true,
      active: true,
    ),
    _TrackingStep(
      title: 'Predată curierului',
      subtitle: 'AWB-ul va fi disponibil după predarea coletului.',
      icon: Icons.local_shipping_outlined,
      done: false,
    ),
    _TrackingStep(
      title: 'Livrată',
      subtitle: 'Comanda ajunge la adresa ta.',
      icon: Icons.home_outlined,
      done: false,
    ),
  ];

  @override
  void dispose() {
    trackingController.dispose();
    super.dispose();
  }

  void searchOrder() {
    final code = trackingController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdu numărul comenzii sau AWB-ul'),
        ),
      );
      return;
    }

    setState(() {
      searchedCode = code;
      searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Order tracking'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          trackingHeader(),
          const SizedBox(height: 16),
          trackingSearch(),
          const SizedBox(height: 18),
          if (searched) trackingResult(),
        ],
      ),
    );
  }

  Widget trackingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_shipping_outlined, color: Colors.white, size: 42),
          SizedBox(height: 14),
          Text(
            'Urmărește comanda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Introdu numărul comenzii sau AWB-ul ca să vezi statusul livrării.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget trackingSearch() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TextField(
            controller: trackingController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchOrder(),
            decoration: InputDecoration(
              hintText: 'Ex: GD-1024 sau AWB123456',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: searchOrder,
              icon: const Icon(Icons.track_changes_outlined),
              label: const Text('Verifică status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget trackingResult() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_outlined, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      searchedCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status curent: În pregătire',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              for (int i = 0; i < demoSteps.length; i++)
                trackingStep(
                  step: demoSteps[i],
                  isLast: i == demoSteps.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget trackingStep({
    required _TrackingStep step,
    required bool isLast,
  }) {
    final color = step.done ? primaryColor : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: step.active ? 42 : 36,
              height: step.active ? 42 : 36,
              decoration: BoxDecoration(
                color: step.done ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color, width: 2),
                boxShadow: step.active
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                step.icon,
                color: step.done ? Colors.white : Colors.grey,
                size: step.active ? 22 : 19,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: step.active ? 5 : 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: step.done ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool active;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    this.active = false,
  });
}
