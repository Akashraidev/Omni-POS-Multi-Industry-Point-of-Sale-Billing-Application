import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';

class GymMember {
  final String id;
  final String name;
  final String phone;
  final String planName;
  final int planDurationDays;
  final DateTime startDate;
  final DateTime expiryDate;
  int attendanceCount;
  final bool hasPersonalTrainer;
  final String? trainerName;
  final String? assignedLocker;
  final double amountPaid;

  GymMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.planName,
    required this.planDurationDays,
    required this.startDate,
    required this.expiryDate,
    this.attendanceCount = 0,
    this.hasPersonalTrainer = false,
    this.trainerName,
    this.assignedLocker,
    required this.amountPaid,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  int get daysRemaining {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpiringSoon => !isExpired && daysRemaining <= 7;
}

class GymMembershipsScreen extends StatefulWidget {
  const GymMembershipsScreen({super.key});

  @override
  State<GymMembershipsScreen> createState() => _GymMembershipsScreenState();
}

class _GymMembershipsScreenState extends State<GymMembershipsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, expiring, expired

  final List<GymMember> _members = [
    GymMember(
      id: 'GM-1001',
      name: 'Devendra Patel',
      phone: '+91 98220 11223',
      planName: 'Annual VIP All-Access',
      planDurationDays: 365,
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      expiryDate: DateTime.now().add(const Duration(days: 275)),
      attendanceCount: 68,
      hasPersonalTrainer: true,
      trainerName: 'Vikram Singh',
      assignedLocker: 'L-04',
      amountPaid: 14000,
    ),
    GymMember(
      id: 'GM-1002',
      name: 'Ananya Deshmukh',
      phone: '+91 98450 33445',
      planName: '3 Months Fitness Pro',
      planDurationDays: 90,
      startDate: DateTime.now().subtract(const Duration(days: 86)),
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      attendanceCount: 42,
      hasPersonalTrainer: false,
      assignedLocker: 'L-12',
      amountPaid: 3800,
    ),
    GymMember(
      id: 'GM-1003',
      name: 'Rohan Sharma',
      phone: '+91 97110 55667',
      planName: 'Monthly Strength Pass',
      planDurationDays: 30,
      startDate: DateTime.now().subtract(const Duration(days: 25)),
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      attendanceCount: 19,
      hasPersonalTrainer: true,
      trainerName: 'Rahul Verma',
      amountPaid: 1500,
    ),
    GymMember(
      id: 'GM-1004',
      name: 'Karan Mehra',
      phone: '+91 99001 77889',
      planName: '6 Months Elite Transformation',
      planDurationDays: 180,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
      expiryDate: DateTime.now().add(const Duration(days: 140)),
      attendanceCount: 31,
      hasPersonalTrainer: true,
      trainerName: 'Priya Sharma',
      assignedLocker: 'L-08',
      amountPaid: 7500,
    ),
    GymMember(
      id: 'GM-1005',
      name: 'Sneha Kapoor',
      phone: '+91 98112 99001',
      planName: 'Monthly Cardio Pass',
      planDurationDays: 30,
      startDate: DateTime.now().subtract(const Duration(days: 35)),
      expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      attendanceCount: 22,
      hasPersonalTrainer: false,
      amountPaid: 1400,
    ),
  ];

  List<GymMember> get _filteredMembers {
    return _members.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.phone.contains(_searchQuery) ||
          m.id.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'active') {
        return !m.isExpired && !m.isExpiringSoon;
      } else if (_selectedFilter == 'expiring') {
        return m.isExpiringSoon;
      } else if (_selectedFilter == 'expired') {
        return m.isExpired;
      }
      return true;
    }).toList();
  }

  void _recordAttendance(GymMember member) {
    setState(() {
      member.attendanceCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFF5722),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Check-in logged for ${member.name}! Total visits: ${member.attendanceCount}'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedPlan = 'Monthly Strength Pass';
    int durationDays = 30;
    double price = 1500;
    bool hasTrainer = false;
    String trainerName = 'Vikram Singh';
    String locker = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: Color(0xFFFF5722)),
              SizedBox(width: 8),
              Text('New Gym Member & Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Member Full Name *',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Phone *',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'Membership Plan *',
                      prefixIcon: Icon(Icons.card_membership_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Monthly Strength Pass', child: Text('Monthly Pass (30 Days) - ₹1,500')),
                      DropdownMenuItem(value: '3 Months Fitness Pro', child: Text('3 Months Pro (90 Days) - ₹3,800')),
                      DropdownMenuItem(value: '6 Months Elite Transformation', child: Text('6 Months Elite (180 Days) - ₹7,000')),
                      DropdownMenuItem(value: 'Annual VIP All-Access', child: Text('Annual VIP (365 Days) - ₹14,000')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          selectedPlan = val;
                          if (val.contains('30')) {
                            durationDays = 30;
                            price = 1500;
                          } else if (val.contains('90')) {
                            durationDays = 90;
                            price = 3800;
                          } else if (val.contains('180')) {
                            durationDays = 180;
                            price = 7000;
                          } else {
                            durationDays = 365;
                            price = 14000;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Add Personal Trainer (PT)'),
                    subtitle: const Text('Assigned coach for workout regime'),
                    value: hasTrainer,
                    activeThumbColor: const Color(0xFFFF5722),
                    onChanged: (val) => setDlgState(() => hasTrainer = val),
                  ),
                  if (hasTrainer) ...[
                    DropdownButtonFormField<String>(
                      initialValue: trainerName,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Trainer',
                        prefixIcon: Icon(Icons.sports_gymnastics_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Vikram Singh', child: Text('Vikram Singh (Senior Coach)')),
                        DropdownMenuItem(value: 'Rahul Verma', child: Text('Rahul Verma (Strength Specialist)')),
                        DropdownMenuItem(value: 'Priya Sharma', child: Text('Priya Sharma (CrossFit / HIIT)')),
                        DropdownMenuItem(value: 'Amit Patel', child: Text('Amit Patel (Cardio & Nutrition)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => trainerName = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Locker Assigned (Optional e.g. L-15)',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    onChanged: (val) => locker = val,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                final now = DateTime.now();
                setState(() {
                  _members.insert(
                    0,
                    GymMember(
                      id: 'GM-${1000 + _members.length + 1}',
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      planName: selectedPlan,
                      planDurationDays: durationDays,
                      startDate: now,
                      expiryDate: now.add(Duration(days: durationDays)),
                      attendanceCount: 1,
                      hasPersonalTrainer: hasTrainer,
                      trainerName: hasTrainer ? trainerName : null,
                      assignedLocker: locker.isNotEmpty ? locker : null,
                      amountPaid: price,
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFFF5722),
                    content: Text('Member "${nameCtrl.text.trim()}" registered successfully!'),
                  ),
                );
              },
              child: const Text('Save & Activate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenewDialog(GymMember member) {
    int renewDays = 30;
    double renewCost = 1500;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Renew Plan: ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Expiry: ${member.expiryDate.day}/${member.expiryDate.month}/${member.expiryDate.year}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: renewDays,
                decoration: const InputDecoration(labelText: 'Renewal Duration'),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('+30 Days (1 Month) - ₹1,500')),
                  DropdownMenuItem(value: 90, child: Text('+90 Days (3 Months) - ₹3,800')),
                  DropdownMenuItem(value: 180, child: Text('+180 Days (6 Months) - ₹7,000')),
                  DropdownMenuItem(value: 365, child: Text('+365 Days (1 Year) - ₹14,000')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() {
                      renewDays = val;
                      renewCost = val == 30
                          ? 1500
                          : val == 90
                              ? 3800
                              : val == 180
                                  ? 7000
                                  : 14000;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              onPressed: () {
                final base = member.isExpired ? DateTime.now() : member.expiryDate;
                setState(() {
                  final index = _members.indexOf(member);
                  if (index != -1) {
                    _members[index] = GymMember(
                      id: member.id,
                      name: member.name,
                      phone: member.phone,
                      planName: '${renewDays}d Renewal Plan',
                      planDurationDays: member.planDurationDays + renewDays,
                      startDate: member.startDate,
                      expiryDate: base.add(Duration(days: renewDays)),
                      attendanceCount: member.attendanceCount,
                      hasPersonalTrainer: member.hasPersonalTrainer,
                      trainerName: member.trainerName,
                      assignedLocker: member.assignedLocker,
                      amountPaid: member.amountPaid + renewCost,
                    );
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFFF5722),
                    content: Text('${member.name} renewed for $renewDays days!'),
                  ),
                );
              },
              child: const Text('Confirm Renewal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _members.where((m) => !m.isExpired && !m.isExpiringSoon).length;
    final expiringCount = _members.where((m) => m.isExpiringSoon).length;
    final expiredCount = _members.where((m) => m.isExpired).length;
    final totalVisits = _members.fold(0, (sum, m) => sum + m.attendanceCount);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: Color(0xFFFF5722)),
            SizedBox(width: 8),
            Text('Gym Memberships & Passes', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('New Member'),
              onPressed: _showAddMemberDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFF5722).withAlpha(15),
            child: Row(
              children: [
                _metricTile('Total Members', '${_members.length}', Icons.groups_rounded, const Color(0xFFFF5722)),
                _metricTile('Active Passes', '$activeCount', Icons.verified_rounded, const Color(0xFF16A34A)),
                _metricTile('Expiring Soon', '$expiringCount', Icons.warning_amber_rounded, const Color(0xFFEA580C)),
                _metricTile('Expired / Due', '$expiredCount', Icons.cancel_outlined, const Color(0xFFDC2626)),
                _metricTile('Check-Ins Logged', '$totalVisits', Icons.fitness_center_rounded, const Color(0xFF8B5CF6)),
              ],
            ),
          ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by member name, phone or ID...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: AppTokens.borderMD),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('all', 'All (${_members.length})'),
                    _filterChip('active', 'Active ($activeCount)'),
                    _filterChip('expiring', 'Expiring ($expiringCount)'),
                    _filterChip('expired', 'Expired ($expiredCount)'),
                  ],
                ),
              ],
            ),
          ),

          // Members List
          Expanded(
            child: _filteredMembers.isEmpty
                ? const Center(
                    child: Text('No gym members match the filter.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return _buildMemberCard(member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTokens.borderMD,
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFF5722).withAlpha(40),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFF5722) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildMemberCard(GymMember member) {
    Color statusColor;
    String statusText;
    if (member.isExpired) {
      statusColor = const Color(0xFFDC2626);
      statusText = 'EXPIRED';
    } else if (member.isExpiringSoon) {
      statusColor = const Color(0xFFEA580C);
      statusText = '${member.daysRemaining} DAYS LEFT';
    } else {
      statusColor = const Color(0xFF16A34A);
      statusText = 'ACTIVE (${member.daysRemaining}d left)';
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFF5722).withAlpha(30),
            child: Text(
              member.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: AppTokens.borderSM,
                        border: Border.all(color: statusColor.withAlpha(80)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(member.id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(member.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(width: 16),
                    Icon(Icons.card_membership_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(member.planName, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (member.hasPersonalTrainer) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(30),
                          borderRadius: AppTokens.borderSM,
                        ),
                        child: Text(
                          'Coach: ${member.trainerName}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (member.assignedLocker != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withAlpha(25),
                          borderRadius: AppTokens.borderSM,
                        ),
                        child: Text(
                          'Locker: ${member.assignedLocker}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Visits: ${member.attendanceCount} | Paid: ₹${member.amountPaid.toInt()}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                label: const Text('Check-In'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5722),
                  side: const BorderSide(color: Color(0xFFFF5722)),
                ),
                onPressed: () => _recordAttendance(member),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                onPressed: () => _showRenewDialog(member),
                child: const Text('Renew Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
