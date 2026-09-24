import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';

class RepairServiceScreen extends StatefulWidget {
  const RepairServiceScreen({super.key});

  @override
  State<RepairServiceScreen> createState() => _RepairServiceScreenState();
}

class _RepairServiceScreenState extends State<RepairServiceScreen> {
  final List<Map<String, dynamic>> _jobCards = [
    {
      'id': 'JOB-501',
      'device': 'MacBook Pro 14" M1',
      'customer': 'Rohan Gupta',
      'phone': '9892011223',
      'issue': 'Battery swelling & thermal throttling',
      'status': 'Diagnosing',
      'estimated_cost': 8500.0,
    },
    {
      'id': 'JOB-502',
      'device': 'Samsung Galaxy S23 Ultra',
      'customer': 'Kavita Joshi',
      'phone': '9820033445',
      'issue': 'Display glass crack replacement',
      'status': 'Repairing',
      'estimated_cost': 14200.0,
    },
    {
      'id': 'JOB-503',
      'device': 'Sony WH-1000XM4',
      'customer': 'Sameer Rao',
      'phone': '9811223344',
      'issue': 'Right ear cup hinge broken',
      'status': 'Ready for Delivery',
      'estimated_cost': 2200.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair & Service Job Cards'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: _jobCards.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
        itemBuilder: (context, index) {
          final job = _jobCards[index];

          BadgeType bType;
          switch (job['status']) {
            case 'Ready for Delivery':
              bType = BadgeType.success;
              break;
            case 'Repairing':
              bType = BadgeType.info;
              break;
            default:
              bType = BadgeType.warning;
          }

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(job['id'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    AppBadge(label: job['status'], type: bType),
                  ],
                ),
                const SizedBox(height: 8),
                Text(job['device'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Reported Issue: ${job['issue']}', style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${job['customer']} (${job['phone']})', style: const TextStyle(fontSize: 13)),
                    Text('Est: ₹${job['estimated_cost'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          if (job['status'] == 'Diagnosing') {
                            job['status'] = 'Repairing';
                          } else if (job['status'] == 'Repairing') {
                            job['status'] = 'Ready for Delivery';
                          } else {
                            _jobCards.removeAt(index);
                          }
                        });
                      },
                      child: Text(
                        job['status'] == 'Diagnosing'
                            ? 'Move to Repair'
                            : (job['status'] == 'Repairing' ? 'Mark Ready' : 'Deliver Device'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
