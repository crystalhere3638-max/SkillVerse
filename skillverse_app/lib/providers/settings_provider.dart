import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only settings (no Firebase). Persisted with SharedPreferences
/// so toggles survive app restarts, same pattern as post drafts.
class SettingsProvider extends ChangeNotifier {
  static const _kNotificationsKey = 'skillverse_settings_notifications_v1';

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _loaded = false;
  bool get loaded => _loaded;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_kNotificationsKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, value);
  }
}
