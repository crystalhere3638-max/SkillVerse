import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../services/interaction_local_storage_service.dart';

class ReportRepository {
  final InteractionLocalStorageService _storage;
  final _uuid = const Uuid();

  ReportRepository({InteractionLocalStorageService? storage})
      : _storage = storage ?? InteractionLocalStorageService();

  Future<void> submit({required String postId, required ReportReason reason}) async {
    final existing = await _storage.loadReports();
    final report = Report(id: _uuid.v4(), postId: postId, reason: reason, createdAt: DateTime.now());
    await _storage.saveReports([...existing, report]);
  }
}
