import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../models/report_model.dart';

class InteractionLocalStorageService {
  static const _kActivityKey = 'skillverse_activity_log_v1';
  static const _kReportsKey = 'skillverse_reports_v1';
  static const _kMaxActivityEntries = 200;

  Future<List<ActivityEntry>> loadActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActivityKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveActivity(List<ActivityEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    // Cap growth so local storage never balloons during heavy testing.
    final trimmed = entries.length > _kMaxActivityEntries
        ? entries.sublist(entries.length - _kMaxActivityEntries)
        : entries;
    await prefs.setString(_kActivityKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  Future<List<Report>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReportsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveReports(List<Report> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReportsKey, jsonEncode(reports.map((r) => r.toJson()).toList()));
  }
}
