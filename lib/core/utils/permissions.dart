import '../../data/models/app_user.dart';

/// Role-based authorization for the Medical/Pharmacy workspace.
///
/// The UI must never surface an action the signed-in operator cannot perform.
/// Capability checks funnel through here so permission logic has exactly one
/// source of truth. Unknown roles fall back to the least-privileged staff set.
class Permissions {
  Permissions._();

  /// Full control of every sector capability.
  static const _ownerCapabilities = <String>{
    Capability.billing,
    Capability.dashboard,
    Capability.viewProducts,
    Capability.manageProducts,
    Capability.managePurchases,
    Capability.viewReports,
    Capability.viewFinancials,
    Capability.viewExpenses,
    Capability.voidSales,
    Capability.manageSettings,
    Capability.manageShift,
  };

  static const _adminCapabilities = <String>{
    Capability.billing,
    Capability.dashboard,
    Capability.viewProducts,
    Capability.manageProducts,
    Capability.managePurchases,
    Capability.viewReports,
    Capability.viewFinancials,
    Capability.viewExpenses,
    Capability.voidSales,
    Capability.manageSettings,
    Capability.manageShift,
  };

  /// Store manager: full operations, no company/security settings.
  static const _managerCapabilities = <String>{
    Capability.billing,
    Capability.dashboard,
    Capability.viewProducts,
    Capability.manageProducts,
    Capability.managePurchases,
    Capability.viewReports,
    Capability.viewFinancials,
    Capability.viewExpenses,
    Capability.voidSales,
    Capability.manageShift,
  };

  /// Counter / billing staff: sell, catalogue lookup, own shift.
  static const _billingCapabilities = <String>{
    Capability.billing,
    Capability.dashboard,
    Capability.viewProducts,
    Capability.manageShift,
  };

  static const Map<String, Set<String>> _byRole = {
    'Owner': _ownerCapabilities,
    'Admin': _adminCapabilities,
    'Manager': _managerCapabilities,
    'Billing': _billingCapabilities,
    'Cashier': _billingCapabilities,
    'Pharmacist': _billingCapabilities,
    'Inventory': _billingCapabilities,
  };

  static Set<String> capabilitiesFor(String role) {
    return _byRole[role] ?? _billingCapabilities;
  }

  /// True when [role] holds [capability].
  static bool can(String role, String capability) {
    return capabilitiesFor(role).contains(capability);
  }

  /// Convenience overload for the current [AppUser].
  static bool userCan(AppUser? user, String capability) {
    return can(user?.role ?? 'Billing', capability);
  }
}

/// Stable capability identifiers used across the app.
class Capability {
  Capability._();

  /// Operate the POS / create sales.
  static const billing = 'billing';

  /// View the dashboard.
  static const dashboard = 'dashboard';

  /// Read the product / medicine catalogue.
  static const viewProducts = 'view_products';

  /// Create / edit / delete products & categories.
  static const manageProducts = 'manage_products';

  /// Create purchases & purchase returns.
  static const managePurchases = 'manage_purchases';

  /// Open reports & analytics.
  static const viewReports = 'view_reports';

  /// See profit, cost and financial aggregates.
  static const viewFinancials = 'view_financials';

  /// See & record expenses.
  static const viewExpenses = 'view_expenses';

  /// Void / refund a completed sale.
  static const voidSales = 'void_sales';

  /// Change company, tax and security settings.
  static const manageSettings = 'manage_settings';

  /// Open / close the work shift.
  static const manageShift = 'manage_shift';
}
