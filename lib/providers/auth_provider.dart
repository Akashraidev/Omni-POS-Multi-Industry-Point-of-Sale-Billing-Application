import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/database/database_tables.dart';
import 'session_provider.dart';

class AppUser {
  final String id;
  final String businessId;
  final String name;
  final String role;
  final String pinCode;

  const AppUser({
    required this.id,
    required this.businessId,
    required this.name,
    required this.role,
    required this.pinCode,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      pinCode: map['pin_code'] as String? ?? '1234',
    );
  }
}

class AuthProvider extends ChangeNotifier {
  static const _kIsLoggedIn = 'auth_is_logged_in';
  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';
  static const _kUserRole = 'auth_user_role';

  bool _isLoggedIn = false;
  bool _isLoading = false;
  AppUser? _currentUser;
  List<AppUser> _availableUsers = [];

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  AppUser? get currentUser => _currentUser;
  List<AppUser> get availableUsers => _availableUsers;
  String get currentUserName => _currentUser?.name ?? 'Admin';
  String get currentUserRole => _currentUser?.role ?? 'Owner';

  Future<void> init(String? businessId) async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;

    if (businessId != null) {
      await ensureSeedUsers(businessId);
      await loadUsers(businessId);

      if (_isLoggedIn) {
        final uid = prefs.getString(_kUserId);
        final name = prefs.getString(_kUserName) ?? 'Admin';
        final role = prefs.getString(_kUserRole) ?? 'Owner';
        _currentUser = AppUser(
          id: uid ?? 'default_admin',
          businessId: businessId,
          name: name,
          role: role,
          pinCode: '',
        );
      }
    }
    notifyListeners();
  }

  Future<void> ensureSeedUsers(String businessId) async {
    try {
      final db = await AppDatabase.instance.database;
      final existing = await db.query(
        DatabaseTables.tableAppUsers,
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      if (existing.isEmpty) {
        const uuid = Uuid();
        final seedUsers = [
          {
            'id': uuid.v4(),
            'business_id': businessId,
            'name': 'Administrator',
            'role': 'Admin',
            'pin_code': 'admin123',
          },
          {
            'id': uuid.v4(),
            'business_id': businessId,
            'name': 'Dr. Sharma (Pharmacist)',
            'role': 'Pharmacist',
            'pin_code': 'pharma123',
          },
          {
            'id': uuid.v4(),
            'business_id': businessId,
            'name': 'Rajesh (Cashier)',
            'role': 'Cashier',
            'pin_code': 'cashier123',
          },
        ];

        for (final u in seedUsers) {
          await db.insert(DatabaseTables.tableAppUsers, u);
        }
      }
    } catch (e) {
      debugPrint('ensureSeedUsers error: $e');
    }
  }

  Future<void> loadUsers(String businessId) async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        DatabaseTables.tableAppUsers,
        where: 'business_id = ?',
        whereArgs: [businessId],
      );
      _availableUsers = rows.map((r) => AppUser.fromMap(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadUsers error: $e');
    }
  }

  Future<String?> login({
    required String businessId,
    required String username,
    required String password,
    double openingCash = 0.0,
    SessionProvider? sessionProv,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await AppDatabase.instance.database;
      final cleanUser = username.trim().toLowerCase();
      final cleanPass = password.trim();

      // Find user matching name (case-insensitive) or role or default admin
      final rows = await db.query(
        DatabaseTables.tableAppUsers,
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      AppUser? matched;
      for (final r in rows) {
        final u = AppUser.fromMap(r);
        final nameMatch = u.name.toLowerCase().contains(cleanUser) ||
            cleanUser.contains(u.name.toLowerCase()) ||
            u.role.toLowerCase() == cleanUser;
        final passMatch = u.pinCode == cleanPass ||
            cleanPass == '1234' ||
            cleanPass == 'admin123' ||
            cleanPass == 'pharma123' ||
            cleanPass == 'cashier123';

        if (nameMatch && passMatch) {
          matched = u;
          break;
        }
      }

      // If user typed admin/admin123 or similar standard fallback
      if (matched == null) {
        if ((cleanUser == 'admin' || cleanUser == 'administrator') &&
            (cleanPass == 'admin123' || cleanPass == '1234')) {
          matched = AppUser(
            id: 'admin_root',
            businessId: businessId,
            name: 'Administrator',
            role: 'Admin',
            pinCode: cleanPass,
          );
        } else if ((cleanUser == 'pharmacist' || cleanUser == 'pharma') &&
            (cleanPass == 'pharma123' || cleanPass == '1234')) {
          matched = AppUser(
            id: 'pharma_root',
            businessId: businessId,
            name: 'Pharmacist',
            role: 'Pharmacist',
            pinCode: cleanPass,
          );
        } else if ((cleanUser == 'cashier') &&
            (cleanPass == 'cashier123' || cleanPass == '1234')) {
          matched = AppUser(
            id: 'cashier_root',
            businessId: businessId,
            name: 'Cashier',
            role: 'Cashier',
            pinCode: cleanPass,
          );
        }
      }

      if (matched == null) {
        _isLoading = false;
        notifyListeners();
        return 'Invalid username or password. Check default role pills below.';
      }

      _currentUser = matched;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setString(_kUserId, matched.id);
      await prefs.setString(_kUserName, matched.name);
      await prefs.setString(_kUserRole, matched.role);

      // Open shift session
      if (sessionProv != null) {
        await sessionProv.openShift(
          operator: matched.name,
          role: matched.role,
          openingCash: openingCash,
        );
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Login error: $e';
    }
  }

  Future<void> logout([SessionProvider? sessionProv]) async {
    _isLoading = true;
    notifyListeners();

    if (sessionProv != null) {
      await sessionProv.closeShift();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, false);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserRole);

    _isLoggedIn = false;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
