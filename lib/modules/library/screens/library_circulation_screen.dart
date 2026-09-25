import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';

class BookCirculationRecord {
  final String id;
  final String bookTitle;
  final String isbn;
  final String borrowerName;
  final String borrowerPhone;
  final String memberCardId;
  final DateTime issueDate;
  DateTime dueDate;
  DateTime? returnDate;
  bool isReturned;
  double finePaid;

  BookCirculationRecord({
    required this.id,
    required this.bookTitle,
    required this.isbn,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.memberCardId,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.isReturned = false,
    this.finePaid = 0.0,
  });

  bool get isOverdue {
    if (isReturned) return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get overdueDays {
    if (isReturned) {
      if (returnDate != null && returnDate!.isAfter(dueDate)) {
        return returnDate!.difference(dueDate).inDays;
      }
      return 0;
    }
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  double calculateFine({double finePerDay = 5.0}) {
    return overdueDays * finePerDay;
  }
}

class LibraryCirculationScreen extends StatefulWidget {
  const LibraryCirculationScreen({super.key});

  @override
  State<LibraryCirculationScreen> createState() => _LibraryCirculationScreenState();
}

class _LibraryCirculationScreenState extends State<LibraryCirculationScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, borrowed, overdue, returned

  final List<BookCirculationRecord> _records = [
    BookCirculationRecord(
      id: 'LEND-201',
      bookTitle: 'Clean Code: A Handbook of Agile Software Craftsmanship',
      isbn: '978-0132350884',
      borrowerName: 'Aditya Kulkarni',
      borrowerPhone: '+91 98231 22445',
      memberCardId: 'LIB-MEM-104',
      issueDate: DateTime.now().subtract(const Duration(days: 20)),
      dueDate: DateTime.now().subtract(const Duration(days: 6)),
      isReturned: false,
    ),
    BookCirculationRecord(
      id: 'LEND-202',
      bookTitle: 'The Psychology of Money',
      isbn: '978-9390166268',
      borrowerName: 'Meera Iyer',
      borrowerPhone: '+91 98450 77889',
      memberCardId: 'LIB-MEM-088',
      issueDate: DateTime.now().subtract(const Duration(days: 8)),
      dueDate: DateTime.now().add(const Duration(days: 6)),
      isReturned: false,
    ),
    BookCirculationRecord(
      id: 'LEND-203',
      bookTitle: 'Sapiens: A Brief History of Humankind',
      isbn: '978-0099590088',
      borrowerName: 'Varun Joshi',
      borrowerPhone: '+91 97660 33221',
      memberCardId: 'LIB-MEM-112',
      issueDate: DateTime.now().subtract(const Duration(days: 12)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      isReturned: false,
    ),
    BookCirculationRecord(
      id: 'LEND-204',
      bookTitle: 'Atomic Habits',
      isbn: '978-1847941831',
      borrowerName: 'Pooja Reddy',
      borrowerPhone: '+91 99011 44556',
      memberCardId: 'LIB-MEM-095',
      issueDate: DateTime.now().subtract(const Duration(days: 25)),
      dueDate: DateTime.now().subtract(const Duration(days: 11)),
      isReturned: false,
    ),
    BookCirculationRecord(
      id: 'LEND-205',
      bookTitle: 'Design Patterns: Elements of Reusable Object-Oriented Software',
      isbn: '978-0201633610',
      borrowerName: 'Sanjay Nair',
      borrowerPhone: '+91 98112 55667',
      memberCardId: 'LIB-MEM-062',
      issueDate: DateTime.now().subtract(const Duration(days: 18)),
      dueDate: DateTime.now().subtract(const Duration(days: 4)),
      returnDate: DateTime.now().subtract(const Duration(days: 1)),
      isReturned: true,
      finePaid: 15.0,
    ),
  ];

  List<BookCirculationRecord> get _filteredRecords {
    return _records.where((r) {
      final q = _searchQuery.toLowerCase();
      final match = r.bookTitle.toLowerCase().contains(q) ||
          r.borrowerName.toLowerCase().contains(q) ||
          r.isbn.contains(q) ||
          r.id.toLowerCase().contains(q) ||
          r.memberCardId.toLowerCase().contains(q);
      if (!match) return false;

      if (_selectedFilter == 'borrowed') {
        return !r.isReturned && !r.isOverdue;
      } else if (_selectedFilter == 'overdue') {
        return r.isOverdue;
      } else if (_selectedFilter == 'returned') {
        return r.isReturned;
      }
      return true;
    }).toList();
  }

  void _showIssueBookDialog() {
    final titleCtrl = TextEditingController();
    final isbnCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cardCtrl = TextEditingController(text: 'LIB-MEM-${100 + _records.length + 1}');
    int durationDays = 14;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.import_contacts_rounded, color: Color(0xFF0369A1)),
              SizedBox(width: 8),
              Text('Issue Book to Reader', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Book Title *',
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: isbnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ISBN / Barcode Code',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reader / Borrower Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Reader Phone *',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cardCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Library Card ID',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: durationDays,
                    decoration: const InputDecoration(
                      labelText: 'Lending Period',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 Days (Short Loan)')),
                      DropdownMenuItem(value: 14, child: Text('14 Days (Standard Loan)')),
                      DropdownMenuItem(value: 28, child: Text('28 Days (Monthly Loan)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => durationDays = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                final now = DateTime.now();
                setState(() {
                  _records.insert(
                    0,
                    BookCirculationRecord(
                      id: 'LEND-${200 + _records.length + 1}',
                      bookTitle: titleCtrl.text.trim(),
                      isbn: isbnCtrl.text.trim().isEmpty ? 'ISBN-CUSTOM-${DateTime.now().millisecondsSinceEpoch % 10000}' : isbnCtrl.text.trim(),
                      borrowerName: nameCtrl.text.trim(),
                      borrowerPhone: phoneCtrl.text.trim(),
                      memberCardId: cardCtrl.text.trim(),
                      issueDate: now,
                      dueDate: now.add(Duration(days: durationDays)),
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0369A1),
                    content: Text('Book "${titleCtrl.text.trim()}" issued to ${nameCtrl.text.trim()}! Due in $durationDays days.'),
                  ),
                );
              },
              child: const Text('Confirm Issue'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(BookCirculationRecord record) {
    final overdueDays = record.overdueDays;
    final fine = record.calculateFine(finePerDay: 5.0);
    bool waiveFine = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_return_rounded, color: Color(0xFF0369A1)),
              SizedBox(width: 8),
              Text('Return Book & Calculate Fine'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Borrower: ${record.borrowerName} (${record.memberCardId})'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: overdueDays > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: AppTokens.borderMD,
                  border: Border.all(color: overdueDays > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overdueDays > 0 ? 'OVERDUE BY $overdueDays DAYS' : 'RETURNED ON TIME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: overdueDays > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overdueDays > 0
                          ? 'Late Fine: $overdueDays days × ₹5/day = ₹${fine.toInt()}'
                          : 'No overdue fines applicable.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (overdueDays > 0) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Waive Off Fine (Admin Discretion)'),
                  value: waiveFine,
                  activeColor: const Color(0xFF0369A1),
                  onChanged: (val) => setDlgState(() => waiveFine = val ?? false),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
              onPressed: () {
                setState(() {
                  record.isReturned = true;
                  record.returnDate = DateTime.now();
                  record.finePaid = waiveFine ? 0.0 : fine;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0369A1),
                    content: Text('Book returned successfully! ${record.finePaid > 0 ? "Fine collected: ₹${record.finePaid.toInt()}" : ""}'),
                  ),
                );
              },
              child: const Text('Accept Return'),
            ),
          ],
        ),
      ),
    );
  }

  void _renewBook(BookCirculationRecord record) {
    setState(() {
      record.dueDate = record.dueDate.add(const Duration(days: 14));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0369A1),
        content: Text('Lending renewed for 14 more days! New due date: ${record.dueDate.day}/${record.dueDate.month}/${record.dueDate.year}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBorrowed = _records.where((r) => !r.isReturned && !r.isOverdue).length;
    final overdueCount = _records.where((r) => r.isOverdue).length;
    final returnedCount = _records.where((r) => r.isReturned).length;
    final totalFinesCollected = _records.fold(0.0, (sum, r) => sum + r.finePaid);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_library_rounded, color: Color(0xFF0369A1)),
            SizedBox(width: 8),
            Text('Library Circulation & Lending', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
              icon: const Icon(Icons.bookmark_add_rounded, size: 18),
              label: const Text('Issue Book'),
              onPressed: _showIssueBookDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0369A1).withAlpha(15),
            child: Row(
              children: [
                _metricTile('Circulating Books', '${_records.length}', Icons.auto_stories_rounded, const Color(0xFF0369A1)),
                _metricTile('Currently Lent', '$activeBorrowed', Icons.import_contacts_rounded, const Color(0xFF0284C7)),
                _metricTile('Overdue / Due', '$overdueCount', Icons.warning_rounded, const Color(0xFFDC2626)),
                _metricTile('Returned', '$returnedCount', Icons.check_circle_rounded, const Color(0xFF16A34A)),
                _metricTile('Fines Collected', '₹${totalFinesCollected.toInt()}', Icons.payments_rounded, const Color(0xFFD97706)),
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
                      hintText: 'Search by title, ISBN, reader name or card ID...',
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
                    _filterChip('all', 'All (${_records.length})'),
                    _filterChip('borrowed', 'Lent ($activeBorrowed)'),
                    _filterChip('overdue', 'Overdue ($overdueCount)'),
                    _filterChip('returned', 'Returned ($returnedCount)'),
                  ],
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: _filteredRecords.isEmpty
                ? const Center(
                    child: Text('No circulation records found matching the query.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _buildCirculationCard(record);
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
      selectedColor: const Color(0xFF0369A1).withAlpha(40),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0369A1) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildCirculationCard(BookCirculationRecord record) {
    Color statusColor;
    String statusText;
    if (record.isReturned) {
      statusColor = const Color(0xFF16A34A);
      statusText = 'RETURNED';
    } else if (record.isOverdue) {
      statusColor = const Color(0xFFDC2626);
      statusText = 'OVERDUE (${record.overdueDays}d - ₹${record.calculateFine().toInt()})';
    } else {
      statusColor = const Color(0xFF0284C7);
      final days = record.dueDate.difference(DateTime.now()).inDays;
      statusText = 'DUE IN ${days < 0 ? 0 : days} DAYS';
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0369A1).withAlpha(25),
              borderRadius: AppTokens.borderMD,
            ),
            child: const Icon(Icons.book_rounded, color: Color(0xFF0369A1), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.bookTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Reader: ${record.borrowerName} (${record.memberCardId})',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text(record.borrowerPhone, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('ISBN: ${record.isbn}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 12),
                    Text(
                      'Issued: ${record.issueDate.day}/${record.issueDate.month} • Due: ${record.dueDate.day}/${record.dueDate.month}/${record.dueDate.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (record.finePaid > 0) ...[
                      const SizedBox(width: 12),
                      Text('Fine Paid: ₹${record.finePaid.toInt()}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!record.isReturned)
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0369A1),
                    side: const BorderSide(color: Color(0xFF0369A1)),
                  ),
                  onPressed: () => _renewBook(record),
                  child: const Text('Renew (+14d)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
                  onPressed: () => _showReturnDialog(record),
                  child: const Text('Return Book'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
