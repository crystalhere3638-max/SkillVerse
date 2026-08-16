import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../services/interaction_local_storage_service.dart';

class ActivityRepository {
  final InteractionLocalStorageService _storage;
  final _uuid = const Uuid();

  ActivityRepository({InteractionLocalStorageService? storage})
      : _storage = storage ?? InteractionLocalStorageService();

  Future<List<ActivityEntry>> load() => _storage.loadActivity();

  Future<List<ActivityEntry>> append({
    required List<ActivityEntry> current,
    required ActivityType type,
    required String postId,
    required String postCategory,
  }) async {
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: type,
      postId: postId,
      postCategory: postCategory,
      timestamp: DateTime.now(),
    );
    final updated = [...current, entry];
    await _storage.saveActivity(updated);
    return updated;
  }
}
