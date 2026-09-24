import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  final List<Map<String, dynamic>> _kitchenOrders = [
    {
      'id': 'KOT-101',
      'table': 'Table 1',
      'time': '8 mins ago',
      'status': 'Preparing',
      'items': [
        {'name': 'Margherita Pizza 11"', 'qty': 1, 'notes': 'Thin crust, extra basil'},
        {'name': 'Hazelnut Cappuccino', 'qty': 2, 'notes': 'Oat milk'},
      ],
    },
    {
      'id': 'KOT-102',
      'table': 'Table 3',
      'time': '3 mins ago',
      'status': 'Placed',
      'items': [
        {'name': 'Creamy Truffle Mushroom Fettuccine', 'qty': 2, 'notes': 'Extra spicy'},
        {'name': 'Cheesy Garlic Pull-Apart', 'qty': 1, 'notes': 'Herbed butter'},
      ],
    },
    {
      'id': 'KOT-103',
      'table': 'Table 7',
      'time': '15 mins ago',
      'status': 'Ready',
      'items': [
        {'name': 'Venetian Espresso Tiramisu', 'qty': 2, 'notes': 'Chilled'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System (KDS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _kitchenOrders.length,
        itemBuilder: (context, index) {
          final kot = _kitchenOrders[index];
          final items = kot['items'] as List;

          BadgeType bType;
          Color headerBg;
          switch (kot['status']) {
            case 'Placed':
              bType = BadgeType.warning;
              headerBg = Colors.amber.withAlpha(30);
              break;
            case 'Preparing':
              bType = BadgeType.info;
              headerBg = Colors.blue.withAlpha(30);
              break;
            case 'Ready':
              bType = BadgeType.success;
              headerBg = Colors.green.withAlpha(30);
              break;
            default:
              bType = BadgeType.neutral;
              headerBg = Colors.grey.withAlpha(30);
          }

          return AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kot['id'],
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            '${kot['table']} • ${kot['time']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      AppBadge(label: kot['status'], type: bType),
                    ],
                  ),
                ),
                // Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(40),
                              borderRadius: AppTokens.borderSM,
                            ),
                            child: Text(
                              '${it['qty']}x',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (it['notes'] != null && it['notes'].toString().isNotEmpty)
                                  Text(
                                    '• ${it['notes']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.deepOrange),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Footer Action
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kot['status'] == 'Ready'
                          ? Colors.green
                          : (kot['status'] == 'Preparing' ? Colors.teal : Colors.blue),
                    ),
                    onPressed: () {
                      setState(() {
                        if (kot['status'] == 'Placed') {
                          kot['status'] = 'Preparing';
                        } else if (kot['status'] == 'Preparing') {
                          kot['status'] = 'Ready';
                        } else {
                          _kitchenOrders.removeAt(index);
                        }
                      });
                    },
                    child: Text(
                      kot['status'] == 'Placed'
                          ? 'Start Preparing'
                          : (kot['status'] == 'Preparing' ? 'Mark Ready' : 'Serve Order'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
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
