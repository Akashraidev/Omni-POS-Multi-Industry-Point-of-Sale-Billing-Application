import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/business_provider.dart';

class TableFloorScreen extends StatefulWidget {
  const TableFloorScreen({super.key});

  @override
  State<TableFloorScreen> createState() => _TableFloorScreenState();
}

class _TableFloorScreenState extends State<TableFloorScreen> {
  String _selectedSection = 'All';

  @override
  Widget build(BuildContext context) {
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;

    final tablesList = (currentBiz?.settings['tables'] as List?) ?? [
      {'id': 'T1', 'name': 'Table 1', 'capacity': 2, 'status': 'Occupied', 'section': 'Indoor'},
      {'id': 'T2', 'name': 'Table 2', 'capacity': 4, 'status': 'Free', 'section': 'Indoor'},
      {'id': 'T3', 'name': 'Table 3', 'capacity': 4, 'status': 'Occupied', 'section': 'Indoor'},
      {'id': 'T4', 'name': 'Table 4', 'capacity': 6, 'status': 'Free', 'section': 'Indoor'},
      {'id': 'T5', 'name': 'Table 5 (Patio)', 'capacity': 2, 'status': 'Reserved', 'section': 'Outdoor Patio'},
      {'id': 'T6', 'name': 'Table 6 (Patio)', 'capacity': 4, 'status': 'Free', 'section': 'Outdoor Patio'},
      {'id': 'T7', 'name': 'Table 7 (Booth)', 'capacity': 6, 'status': 'Billing', 'section': 'Lounge'},
      {'id': 'T8', 'name': 'Table 8 (Booth)', 'capacity': 8, 'status': 'Free', 'section': 'Lounge'},
    ];

    final sections = ['All', 'Indoor', 'Outdoor Patio', 'Lounge'];

    final filteredTables = _selectedSection == 'All'
        ? tablesList
        : tablesList.where((t) => t['section'] == _selectedSection).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Table Floor Plan'),
      ),
      body: Column(
        children: [
          // Section Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceMD),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sections.map((sec) {
                  final isSel = _selectedSection == sec;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(sec),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedSection = sec),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: filteredTables.length,
              itemBuilder: (context, index) {
                final table = filteredTables[index];
                final status = table['status'] as String;

                Color statusColor;
                BadgeType bType;
                switch (status) {
                  case 'Occupied':
                    statusColor = Colors.red;
                    bType = BadgeType.error;
                    break;
                  case 'Reserved':
                    statusColor = Colors.amber;
                    bType = BadgeType.warning;
                    break;
                  case 'Billing':
                    statusColor = Colors.purple;
                    bType = BadgeType.info;
                    break;
                  case 'Free':
                  default:
                    statusColor = const Color(0xFF10B981);
                    bType = BadgeType.success;
                }

                return AppCard(
                  borderColor: statusColor.withAlpha(80),
                  onTap: () {
                    _showTableOptions(context, table);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.table_restaurant_rounded, color: statusColor, size: 20),
                          ),
                          AppBadge(label: status, type: bType),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            table['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seats: ${table['capacity']} guests • ${table['section']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(BuildContext context, Map<String, dynamic> table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${table['name']} Options',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Current Status: ${table['status']} | Capacity: ${table['capacity']} guests'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Mark as Free'),
                onTap: () {
                  setState(() => table['status'] = 'Free');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline, color: Colors.red),
                title: const Text('Mark as Occupied'),
                onTap: () {
                  setState(() => table['status'] = 'Occupied');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: Colors.purple),
                title: const Text('Generate Bill / Print KOT'),
                onTap: () {
                  setState(() => table['status'] = 'Billing');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
