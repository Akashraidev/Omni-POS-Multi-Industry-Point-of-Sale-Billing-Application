import 'package:flutter/material.dart';

enum BusinessType {
  medical,
  restaurant,
  grocery,
  gym,
  library,
  electronics,
  garment,
}

extension BusinessTypeExtension on BusinessType {
  String get id {
    switch (this) {
      case BusinessType.medical:
        return 'medical';
      case BusinessType.restaurant:
        return 'restaurant';
      case BusinessType.grocery:
        return 'grocery';
      case BusinessType.gym:
        return 'gym';
      case BusinessType.library:
        return 'library';
      case BusinessType.electronics:
        return 'electronics';
      case BusinessType.garment:
        return 'garment';
    }
  }

  String get displayName {
    switch (this) {
      case BusinessType.medical:
        return 'Medical / Pharmacy';
      case BusinessType.restaurant:
        return 'Restaurant / Cafe';
      case BusinessType.grocery:
        return 'Grocery / Kirana';
      case BusinessType.gym:
        return 'Gym & Fitness Center';
      case BusinessType.library:
        return 'Library & Book Store';
      case BusinessType.electronics:
        return 'Electronics & Gadgets';
      case BusinessType.garment:
        return 'Garments & Apparel';
    }
  }

  String get shortName {
    switch (this) {
      case BusinessType.medical:
        return 'Medical';
      case BusinessType.restaurant:
        return 'Restaurant';
      case BusinessType.grocery:
        return 'Grocery';
      case BusinessType.gym:
        return 'Gym';
      case BusinessType.library:
        return 'Library';
      case BusinessType.electronics:
        return 'Electronics';
      case BusinessType.garment:
        return 'Garments';
    }
  }

  String get tagLine {
    switch (this) {
      case BusinessType.medical:
        return 'FEFO batch expiry, Schedule H/H1 Rx flags, and drug salt register.';
      case BusinessType.restaurant:
        return 'Table floor plans, KDS kitchen tickets, and modifier add-ons.';
      case BusinessType.grocery:
        return 'Weight pricing, fast barcode checkout, and aisle rack mapping.';
      case BusinessType.gym:
        return 'Memberships, trainer plans, workout passes, attendance & supplements.';
      case BusinessType.library:
        return 'Book catalog, ISBN tracker, borrow & return ledger, and overdue fines.';
      case BusinessType.electronics:
        return 'Serial/IMEI tracker, warranty cards, AMC, and repair tickets.';
      case BusinessType.garment:
        return 'Size × Color variant matrix, season tags, and fast size exchange.';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessType.medical:
        return Icons.local_pharmacy_rounded;
      case BusinessType.restaurant:
        return Icons.restaurant_rounded;
      case BusinessType.grocery:
        return Icons.shopping_basket_rounded;
      case BusinessType.gym:
        return Icons.fitness_center_rounded;
      case BusinessType.library:
        return Icons.local_library_rounded;
      case BusinessType.electronics:
        return Icons.devices_other_rounded;
      case BusinessType.garment:
        return Icons.checkroom_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case BusinessType.medical:
        return const Color(0xFF0D9488); // Teal
      case BusinessType.restaurant:
        return const Color(0xFFE11D48); // Rose / Warm Crimson
      case BusinessType.grocery:
        return const Color(0xFF16A34A); // Emerald / Green
      case BusinessType.gym:
        return const Color(0xFFFF5722); // Athletic Punch Flame
      case BusinessType.library:
        return const Color(0xFF0369A1); // Scholarly Sapphire Blue
      case BusinessType.electronics:
        return const Color(0xFF4F46E5); // Indigo
      case BusinessType.garment:
        return const Color(0xFF9333EA); // Purple
    }
  }

  Color get secondaryColor {
    switch (this) {
      case BusinessType.medical:
        return const Color(0xFF14B8A6);
      case BusinessType.restaurant:
        return const Color(0xFFF59E0B);
      case BusinessType.grocery:
        return const Color(0xFF84CC16);
      case BusinessType.gym:
        return const Color(0xFFF59E0B);
      case BusinessType.library:
        return const Color(0xFFD97706);
      case BusinessType.electronics:
        return const Color(0xFF06B6D4);
      case BusinessType.garment:
        return const Color(0xFFF43F5E);
    }
  }

  /// Soft tinted background used on cards / chips for this sector.
  Color get tint {
    return primaryColor.withAlpha(22);
  }

  static BusinessType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'medical':
        return BusinessType.medical;
      case 'restaurant':
        return BusinessType.restaurant;
      case 'grocery':
        return BusinessType.grocery;
      case 'gym':
        return BusinessType.gym;
      case 'library':
        return BusinessType.library;
      case 'electronics':
        return BusinessType.electronics;
      case 'garment':
        return BusinessType.garment;
      case 'supermarket':
        return BusinessType.grocery; // Graceful fallback for legacy records
      default:
        return BusinessType.grocery;
    }
  }
}
