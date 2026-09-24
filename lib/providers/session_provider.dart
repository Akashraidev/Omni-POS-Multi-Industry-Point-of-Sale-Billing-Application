import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Work-session / shift state for the signed-in operator.
///
/// Deliberately backed by [SharedPreferences] rather than a new DB table: a
/// shift only needs to survive app restarts, while all the *money* it reports
/// on is already sourced from the sales ledger. This keeps the shift feature
/// dependency-free (no migration) and never out of sync with real invoices.
class SessionProvider extends ChangeNotifier {
  static const _kOpenAt = 'shift_open_at';
  static const _kOperator = 'shift_operator';
  static const _kRole = 'shift_role';
  static const _kOpeningCash = 'shift_opening_cash';
  static const _kLastCloseAt = 'shift_last_close_at';
  static const _kLastDuration = 'shift_last_duration_min';

  bool _isOpen = false;
  DateTime? _openedAt;
  String _operator = '';
  String _role = '';
  double _openingCash = 0.0;
  DateTime? _lastClosedAt;
  int _lastDurationMinutes = 0;

  bool get isOpen => _isOpen;
  DateTime? get openedAt => _openedAt;
  String get operator => _operator;
  String get role => _role;
  double get openingCash => _openingCash;
  DateTime? get lastClosedAt => _lastClosedAt;
  int get lastDurationMinutes => _lastDurationMinutes;

  /// Elapsed minutes of the currently open shift (0 when closed).
  int get elapsedMinutes {
    if (!_isOpen || _openedAt == null) return 0;
    return DateTime.now().difference(_openedAt!).inMinutes;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final openMs = prefs.getInt(_kOpenAt);
    _isOpen = openMs != null;
    _openedAt = openMs != null ? DateTime.fromMillisecondsSinceEpoch(openMs) : null;
    _operator = prefs.getString(_kOperator) ?? '';
    _role = prefs.getString(_kRole) ?? '';
    _openingCash = prefs.getDouble(_kOpeningCash) ?? 0.0;
    final closedMs = prefs.getInt(_kLastCloseAt);
    _lastClosedAt = closedMs != null ? DateTime.fromMillisecondsSinceEpoch(closedMs) : null;
    _lastDurationMinutes = prefs.getInt(_kLastDuration) ?? 0;
    notifyListeners();
  }

  Future<void> openShift({
    required String operator,
    required String role,
    double openingCash = 0.0,
  }) async {
    _isOpen = true;
    _openedAt = DateTime.now();
    _operator = operator;
    _role = role;
    _openingCash = openingCash;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kOpenAt, _openedAt!.millisecondsSinceEpoch);
    await prefs.setString(_kOperator, _operator);
    await prefs.setString(_kRole, _role);
    await prefs.setDouble(_kOpeningCash, _openingCash);
    notifyListeners();
  }

  Future<void> closeShift() async {
    if (!_isOpen) return;

    final closedAt = DateTime.now();
    _lastClosedAt = closedAt;
    _lastDurationMinutes = _openedAt != null ? closedAt.difference(_openedAt!).inMinutes : 0;

    _isOpen = false;
    _openedAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOpenAt);
    await prefs.setInt(_kLastCloseAt, closedAt.millisecondsSinceEpoch);
    await prefs.setInt(_kLastDuration, _lastDurationMinutes);
    notifyListeners();
  }

  /// Human readable "opened HH:mm" label for the dashboard strip.
  String get openedAtLabel {
    if (_openedAt == null) return '—';
    final h = _openedAt!.hour.toString().padLeft(2, '0');
    final m = _openedAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Elapsed time as "3h 12m".
  String get elapsedLabel {
    final mins = elapsedMinutes;
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
