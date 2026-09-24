import 'package:flutter/material.dart';
import '../../data/models/cart_item.dart';
import '../business_type.dart';

class BusinessNavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const BusinessNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

abstract class BusinessModuleInterface {
  BusinessType get type;
  String get id;
  String get name;
  String get description;
  IconData get icon;

  /// Custom navigation tabs dedicated to this business domain
  List<BusinessNavigationItem> get navigationItems;

  /// Business-specific hero widget injected into the Dynamic Dashboard
  Widget buildDashboardWidget(BuildContext context);

  /// Custom badge/indicator rendered inside POS Cart items
  Widget? buildCartItemExtra(BuildContext context, CartItem item);

  /// Dynamic extra form fields in the Product Create/Edit screen
  Widget? buildProductFormFields(
    BuildContext context,
    Map<String, dynamic> currentMetadata,
    void Function(Map<String, dynamic> updated) onChanged,
  );
}
