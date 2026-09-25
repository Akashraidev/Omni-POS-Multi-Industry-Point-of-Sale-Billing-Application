import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';

class LibraryBook {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String rackLocation;
  int totalCopies;
  int issuedCopies;
  final double? price;

  LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.rackLocation,
    required this.totalCopies,
    this.issuedCopies = 0,
    this.price,
  });

  int get availableCopies => totalCopies - issuedCopies;
}

class LibraryCatalogScreen extends StatefulWidget {
  const LibraryCatalogScreen({super.key});

  @override
  State<LibraryCatalogScreen> createState() => _LibraryCatalogScreenState();
}

class _LibraryCatalogScreenState extends State<LibraryCatalogScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<LibraryBook> _books = [
    LibraryBook(
      id: 'BK-101',
      title: 'Clean Code: A Handbook of Agile Software Craftsmanship',
      author: 'Robert C. Martin',
      isbn: '978-0132350884',
      category: 'Computer Science',
      rackLocation: 'Rack CS-01, Shelf 2',
      totalCopies: 5,
      issuedCopies: 2,
      price: 650,
    ),
    LibraryBook(
      id: 'BK-102',
      title: 'The Pragmatic Programmer: Your Journey To Mastery',
      author: 'David Thomas, Andrew Hunt',
      isbn: '978-0135957059',
      category: 'Computer Science',
      rackLocation: 'Rack CS-01, Shelf 3',
      totalCopies: 4,
      issuedCopies: 1,
      price: 799,
    ),
    LibraryBook(
      id: 'BK-103',
      title: 'The Psychology of Money',
      author: 'Morgan Housel',
      isbn: '978-9390166268',
      category: 'Business & Finance',
      rackLocation: 'Rack B-03, Shelf 1',
      totalCopies: 6,
      issuedCopies: 3,
      price: 399,
    ),
    LibraryBook(
      id: 'BK-104',
      title: 'Sapiens: A Brief History of Humankind',
      author: 'Yuval Noah Harari',
      isbn: '978-0099590088',
      category: 'History & Humanity',
      rackLocation: 'Rack H-02, Shelf 4',
      totalCopies: 5,
      issuedCopies: 2,
      price: 499,
    ),
    LibraryBook(
      id: 'BK-105',
      title: 'Atomic Habits: An Easy & Proven Way to Build Good Habits',
      author: 'James Clear',
      isbn: '978-1847941831',
      category: 'Self-Help & Philosophy',
      rackLocation: 'Rack SH-04, Shelf 2',
      totalCopies: 8,
      issuedCopies: 4,
      price: 450,
    ),
    LibraryBook(
      id: 'BK-106',
      title: 'Introduction to Algorithms (CLRS)',
      author: 'Thomas H. Cormen, Charles E. Leiserson',
      isbn: '978-0262033848',
      category: 'Computer Science',
      rackLocation: 'Rack CS-02, Shelf 1',
      totalCopies: 3,
      issuedCopies: 1,
      price: 1250,
    ),
  ];

  List<String> get _categories {
    final set = {'All', ..._books.map((b) => b.category)};
    return set.toList();
  }

  List<LibraryBook> get _filteredBooks {
    return _books.where((b) {
      final q = _searchQuery.toLowerCase();
      final match = b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.isbn.contains(q) ||
          b.rackLocation.toLowerCase().contains(q);
      if (!match) return false;

      if (_selectedCategory != 'All' && b.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showAddBookDialog() {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final isbnCtrl = TextEditingController();
    final rackCtrl = TextEditingController();
    final copiesCtrl = TextEditingController(text: '3');
    final priceCtrl = TextEditingController(text: '499');
    String category = 'Computer Science';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.library_add_rounded, color: Color(0xFF0369A1)),
              SizedBox(width: 8),
              Text('Add Book to Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Book Title *', prefixIcon: Icon(Icons.book_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorCtrl,
                    decoration: const InputDecoration(labelText: 'Author(s) *', prefixIcon: Icon(Icons.person_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: isbnCtrl,
                    decoration: const InputDecoration(labelText: 'ISBN-13 Barcode', prefixIcon: Icon(Icons.qr_code_rounded)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Genre / Category', prefixIcon: Icon(Icons.category_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'Computer Science', child: Text('Computer Science & Tech')),
                      DropdownMenuItem(value: 'Business & Finance', child: Text('Business & Finance')),
                      DropdownMenuItem(value: 'History & Humanity', child: Text('History & Humanity')),
                      DropdownMenuItem(value: 'Self-Help & Philosophy', child: Text('Self-Help & Philosophy')),
                      DropdownMenuItem(value: 'Literature & Fiction', child: Text('Literature & Fiction')),
                      DropdownMenuItem(value: 'Science & Medicine', child: Text('Science & Medicine')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rackCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Shelf / Rack Location (e.g. Rack A-02, Shelf 3)',
                      prefixIcon: Icon(Icons.shelves),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: copiesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Copies', prefixIcon: Icon(Icons.copy_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Retail Price (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                        ),
                      ),
                    ],
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
                if (titleCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty) return;
                setState(() {
                  _books.insert(
                    0,
                    LibraryBook(
                      id: 'BK-${100 + _books.length + 1}',
                      title: titleCtrl.text.trim(),
                      author: authorCtrl.text.trim(),
                      isbn: isbnCtrl.text.trim().isEmpty ? 'ISBN-GEN-${DateTime.now().millisecondsSinceEpoch % 100000}' : isbnCtrl.text.trim(),
                      category: category,
                      rackLocation: rackCtrl.text.trim().isEmpty ? 'General Stacks' : rackCtrl.text.trim(),
                      totalCopies: int.tryParse(copiesCtrl.text) ?? 3,
                      price: double.tryParse(priceCtrl.text) ?? 499,
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0369A1),
                    content: Text('Added "${titleCtrl.text.trim()}" to library catalog!'),
                  ),
                );
              },
              child: const Text('Save Book'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTitles = _books.length;
    final totalCopies = _books.fold(0, (sum, b) => sum + b.totalCopies);
    final totalIssued = _books.fold(0, (sum, b) => sum + b.issuedCopies);
    final totalAvailable = totalCopies - totalIssued;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF0369A1)),
            SizedBox(width: 8),
            Text('Library Catalog & Shelf Racks', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Title'),
              onPressed: _showAddBookDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0369A1).withAlpha(15),
            child: Row(
              children: [
                _metricTile('Catalog Titles', '$totalTitles', Icons.menu_book_rounded, const Color(0xFF0369A1)),
                _metricTile('Total Volume Copies', '$totalCopies', Icons.layers_rounded, const Color(0xFF0284C7)),
                _metricTile('Available on Shelf', '$totalAvailable', Icons.check_circle_outline_rounded, const Color(0xFF16A34A)),
                _metricTile('Currently Lent Out', '$totalIssued', Icons.outbox_rounded, const Color(0xFFEA580C)),
              ],
            ),
          ),

          // Search and Category Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, ISBN or rack location...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: AppTokens.borderMD),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0369A1).withAlpha(35),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF0369A1) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Book List
          Expanded(
            child: _filteredBooks.isEmpty
                ? const Center(
                    child: Text('No books found in catalog.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return _buildBookCard(book);
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

  Widget _buildBookCard(LibraryBook book) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0369A1).withAlpha(20),
              borderRadius: AppTokens.borderMD,
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0369A1), size: 28),
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
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: book.availableCopies > 0 ? const Color(0xFF16A34A).withAlpha(20) : const Color(0xFFDC2626).withAlpha(20),
                        borderRadius: AppTokens.borderSM,
                      ),
                      child: Text(
                        book.availableCopies > 0 ? '${book.availableCopies} Available' : 'All Lent Out',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: book.availableCopies > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'By ${book.author} • Category: ${book.category}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withAlpha(20),
                        borderRadius: AppTokens.borderSM,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shelves, size: 13, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text(book.rackLocation, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text('ISBN: ${book.isbn}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('Total: ${book.totalCopies} copies', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (book.price != null)
                      Text('Retail: ₹${book.price!.toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
