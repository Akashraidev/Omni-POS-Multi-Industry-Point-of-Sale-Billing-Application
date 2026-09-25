import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';

class GymTrainerScheduleScreen extends StatefulWidget {
  const GymTrainerScheduleScreen({super.key});

  @override
  State<GymTrainerScheduleScreen> createState() => _GymTrainerScheduleScreenState();
}

class _GymTrainerScheduleScreenState extends State<GymTrainerScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _batches = [
    {
      'title': 'Morning Cardio & Agility',
      'time': '06:00 AM - 07:30 AM',
      'trainer': 'Vikram Singh',
      'enrolled': 22,
      'capacity': 25,
      'category': 'Cardio / Fat Loss',
      'color': 0xFFFF5722,
    },
    {
      'title': 'Iron Strength & Hypertrophy',
      'time': '08:00 AM - 09:30 AM',
      'trainer': 'Rahul Verma',
      'enrolled': 18,
      'capacity': 20,
      'category': 'Weightlifting & Power',
      'color': 0xFFEA580C,
    },
    {
      'title': 'CrossFit & Core Conditioning',
      'time': '05:00 PM - 06:30 PM',
      'trainer': 'Priya Sharma',
      'enrolled': 24,
      'capacity': 25,
      'category': 'HIIT & Endurance',
      'color': 0xFFD97706,
    },
    {
      'title': 'Evening Power Yoga & Calisthenics',
      'time': '07:00 PM - 08:30 PM',
      'trainer': 'Amit Patel',
      'enrolled': 15,
      'capacity': 20,
      'category': 'Flexibility & Strength',
      'color': 0xFF10B981,
    },
  ];

  final List<Map<String, dynamic>> _trainers = [
    {
      'name': 'Vikram Singh',
      'role': 'Head Strength & Conditioning Coach',
      'exp': '8+ Years',
      'clients': 24,
      'rating': 4.9,
      'phone': '+91 98221 44556',
      'slots': 'Morning & Evening',
    },
    {
      'name': 'Rahul Verma',
      'role': 'Bodybuilding & Powerlifting Specialist',
      'exp': '6+ Years',
      'clients': 19,
      'rating': 4.8,
      'phone': '+91 98772 33441',
      'slots': 'Morning Batches',
    },
    {
      'name': 'Priya Sharma',
      'role': 'CrossFit Level 2 & Functional Fitness Coach',
      'exp': '5+ Years',
      'clients': 22,
      'rating': 4.9,
      'phone': '+91 99112 88990',
      'slots': 'Evening Batches',
    },
    {
      'name': 'Amit Patel',
      'role': 'Certified Nutritionist & Mobility Trainer',
      'exp': '7+ Years',
      'clients': 17,
      'rating': 4.7,
      'phone': '+91 98334 11229',
      'slots': 'All Slots',
    },
  ];

  final List<Map<String, dynamic>> _lockers = List.generate(24, (i) {
    final num = i + 1;
    final id = 'L-${num.toString().padLeft(2, '0')}';
    final isOccupied = (i % 3 != 0);
    return {
      'id': id,
      'isOccupied': isOccupied,
      'assignedTo': isOccupied ? 'Member #100${i + 1}' : null,
    };
  });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_gymnastics_rounded, color: Color(0xFFFF5722)),
            SizedBox(width: 8),
            Text('Trainers, Slots & Lockers', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5722),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF5722),
          tabs: const [
            Tab(icon: Icon(Icons.schedule_rounded), text: 'Workout Batches'),
            Tab(icon: Icon(Icons.badge_rounded), text: 'Trainer Roster'),
            Tab(icon: Icon(Icons.lock_rounded), text: 'Locker Allocation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBatchesTab(),
          _buildTrainersTab(),
          _buildLockersTab(),
        ],
      ),
    );
  }

  Widget _buildBatchesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final b = _batches[index];
        final enrolled = b['enrolled'] as int;
        final capacity = b['capacity'] as int;
        final pct = enrolled / capacity;
        final color = Color(b['color'] as int);

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: AppTokens.borderMD),
                    child: Icon(Icons.fitness_center_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          '${b['time']} • Coach: ${b['trainer']} • ${b['category']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: AppTokens.borderSM,
                    ),
                    child: Text(
                      '$enrolled / $capacity Enrolled',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trainers.length,
      itemBuilder: (context, index) {
        final t = _trainers[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFF5722).withAlpha(25),
                child: const Icon(Icons.person_rounded, color: Color(0xFFFF5722), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(35),
                            borderRadius: AppTokens.borderSM,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text('${t['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(t['role'] as String, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 3),
                    Text(
                      'Exp: ${t['exp']} • Active PT Clients: ${t['clients']} • Available: ${t['slots']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5722),
                  side: const BorderSide(color: Color(0xFFFF5722)),
                ),
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Contact'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dialing coach ${t['name']} (${t['phone']})...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Club Locker Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              _legendDot(const Color(0xFF16A34A), 'Available'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFDC2626), 'Occupied'),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: _lockers.length,
              itemBuilder: (context, index) {
                final l = _lockers[index];
                final isOccupied = l['isOccupied'] as bool;
                final color = isOccupied ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

                return InkWell(
                  onTap: () {
                    if (isOccupied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l['id']} is assigned to ${l['assignedTo']}')),
                      );
                    } else {
                      setState(() {
                        l['isOccupied'] = true;
                        l['assignedTo'] = 'New Member';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFFF5722),
                          content: Text('${l['id']} assigned!'),
                        ),
                      );
                    }
                  },
                  borderRadius: AppTokens.borderMD,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      border: Border.all(color: color.withAlpha(90)),
                      borderRadius: AppTokens.borderMD,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isOccupied ? Icons.lock_rounded : Icons.lock_open_rounded, color: color, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          l['id'] as String,
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
