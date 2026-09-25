import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/library_catalog_screen.dart';
import 'screens/library_circulation_screen.dart';

class LibraryBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.library;

  @override
  String get id => 'library';

  @override
  String get name => 'Library & Book Store';

  @override
  String get description => 'Book catalog, ISBN tracker, borrow & return ledger, and overdue fines.';

  @override
  IconData get icon => Icons.local_library_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'library_circulation',
          label: 'Circulation',
          icon: Icons.assignment_return_outlined,
          selectedIcon: Icons.assignment_return_rounded,
          screen: LibraryCirculationScreen(),
        ),
        const BusinessNavigationItem(
          id: 'library_catalog',
          label: 'Book Catalog',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          screen: LibraryCatalogScreen(),
        ),
      ];

  @override
  Widget buildDashboardWidget(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.local_library_rounded, color: Color(0xFF0369A1), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Library Circulation & Lending Desk',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.import_contacts_rounded, size: 16),
                label: const Text('Circulation Ledger'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryCirculationScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryCirculationScreen()),
                    );
                  },
                  borderRadius: AppTokens.borderMD,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1).withAlpha(18),
                      borderRadius: AppTokens.borderMD,
                      border: Border.all(color: const Color(0xFF0369A1).withAlpha(40)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('54 Books Issued', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
                        SizedBox(height: 2),
                        Text('6 Books Overdue • ₹340 Fine Pending', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryCatalogScreen()),
                    );
                  },
                  borderRadius: AppTokens.borderMD,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(18),
                      borderRadius: AppTokens.borderMD,
                      border: Border.all(color: const Color(0xFF0284C7).withAlpha(40)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1,250 Titles Cataloged', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                        SizedBox(height: 2),
                        Text('Mapped across 18 Shelf Racks', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildCartItemExtra(BuildContext context, CartItem item) {
    final meta = item.product.metadata;
    if (meta['isbn'] != null || meta['rack_location'] != null) {
      final isbn = meta['isbn'] != null ? 'ISBN: ${meta['isbn']}' : '';
      final rack = meta['rack_location'] != null ? 'Rack: ${meta['rack_location']}' : '';
      final separator = (isbn.isNotEmpty && rack.isNotEmpty) ? ' • ' : '';
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0369A1).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          '$isbn$separator$rack',
          style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
        ),
      );
    }
    return null;
  }

  @override
  Widget? buildProductFormFields(
    BuildContext context,
    Map<String, dynamic> currentMetadata,
    void Function(Map<String, dynamic> updated) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Library & Book Metadata', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['isbn']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'ISBN-10 / ISBN-13 Code',
            prefixIcon: Icon(Icons.qr_code_rounded),
          ),
          onChanged: (val) {
            currentMetadata['isbn'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['author']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Author / Editor Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onChanged: (val) {
            currentMetadata['author'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['rack_location']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Shelf / Rack Location (e.g. Rack CS-01, Shelf 2)',
            prefixIcon: Icon(Icons.shelves),
          ),
          onChanged: (val) {
            currentMetadata['rack_location'] = val;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
