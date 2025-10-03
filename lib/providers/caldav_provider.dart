import 'package:flutter/material.dart';
import '../services/caldav_service.dart';

class CalDAVProvider extends ChangeNotifier {
  final CalDAVService _caldavService = CalDAVService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;
  final List<CalDAVAccount> _accounts = [];

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  List<CalDAVAccount> get accounts => _accounts;

  Future<void> addAccount(
    String serverUrl,
    String username,
    String password,
  ) async {
    try {
      final account = CalDAVAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      // Verify connection
      await _caldavService.verifyConnection(account);

      _accounts.add(account);
      notifyListeners();

      // Save accounts to storage
      await _saveAccounts();
    } catch (e) {
      debugPrint('Error adding CalDAV account: $e');
      rethrow;
    }
  }

  Future<void> removeAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
    notifyListeners();
    await _saveAccounts();
  }

  Future<void> syncCalendars() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      for (final account in _accounts) {
        await _caldavService.syncCalendar(account);
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _syncError = e.toString();
      debugPrint('Error syncing calendars: $e');
    }

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    // Save to SharedPreferences
    // Implementation depends on security requirements
  }

  Future<void> loadAccounts() async {
    // Load from SharedPreferences
    // Implementation depends on security requirements
  }
}

class CalDAVAccount {
  final String id;
  final String serverUrl;
  final String username;
  final String password;
  final String? displayName;

  CalDAVAccount({
    required this.id,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.displayName,
  });
}
