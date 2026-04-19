import '../../../core/constants/app_constants.dart';
import '../../../core/contracts/app_contracts.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/utils/time_of_day_segment.dart';

class UserLibraryRepositoryImpl implements UserLibraryRepository {
  UserLibraryRepositoryImpl(this._storageService);

  final LocalStorageService _storageService;

  dynamic get _favoritesBox => _storageService.box(AppConstants.favoritesBox);
  dynamic get _recentBox => _storageService.box(AppConstants.recentlyPlayedBox);
  dynamic get _statsBox => _storageService.box(AppConstants.playStatsBox);
  dynamic get _sleepBox => _storageService.box(AppConstants.sleepTimerBox);
  dynamic get _equalizerBox => _storageService.box(AppConstants.equalizerBox);

  @override
  Future<void> clearHistory() async {
    await _recentBox.clear();
    await _statsBox.clear();
  }

  @override
  Future<EqualizerPreset?> getEqualizerPreset() async {
    final raw = _equalizerBox.get('current');
    if (raw is! Map) {
      return null;
    }
    return EqualizerPreset.fromMap(raw);
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    return _favoritesBox.keys
        .map((key) => int.tryParse(key.toString()))
        .whereType<int>()
        .toSet();
  }

  @override
  Future<List<Track>> getFavoriteTracks(List<Track> library) async {
    final ids = await getFavoriteIds();
    return library.where((track) => ids.contains(track.id)).toList();
  }

  @override
  Future<Map<int, PlayStats>> getPlayStats() async {
    final output = <int, PlayStats>{};
    for (final entry in _statsBox.values) {
      if (entry is Map) {
        final stat = PlayStats.fromMap(entry);
        output[stat.trackId] = stat;
      }
    }
    return output;
  }

  @override
  Future<List<Track>> getRecentlyPlayed(List<Track> library) async {
    final index = {for (final track in library) track.id: track};
    final values = _recentBox.values
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a['playedAt'] as String? ?? '');
        final bTime = DateTime.tryParse(b['playedAt'] as String? ?? '');
        return (bTime ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(aTime ?? DateTime.fromMillisecondsSinceEpoch(0));
      });

    return values
        .map((entry) => index[entry['trackId'] as int])
        .whereType<Track>()
        .toList();
  }

  @override
  Future<SleepTimerState> getSleepTimer() async {
    final raw = _sleepBox.get('current');
    if (raw is! Map) {
      return const SleepTimerState(isActive: false);
    }
    return SleepTimerState.fromMap(raw);
  }

  @override
  Future<void> recordPlayEvent(PlayEvent event) async {
    final existing = _statsBox.get(event.trackId.toString());
    final base = existing is Map
        ? PlayStats.fromMap(existing)
        : PlayStats(
            trackId: event.trackId,
            playCount: 0,
            skipCount: 0,
            completionCount: 0,
          );

    final next = base.registerPlay(
      listened: event.listened,
      duration: event.duration,
      completed: event.completed,
      skipped: event.skipped,
      segment: resolveTimeSegment(DateTime.now()),
    );

    await _statsBox.put(event.trackId.toString(), next.toMap());
    await _recentBox.put(
      '${event.trackId}_${DateTime.now().microsecondsSinceEpoch}',
      {
        'trackId': event.trackId,
        'playedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> saveEqualizerPreset(EqualizerPreset preset) {
    return _equalizerBox.put('current', preset.toMap());
  }

  @override
  Future<void> saveSleepTimer(SleepTimerState state) {
    return _sleepBox.put('current', state.toMap());
  }

  @override
  Future<void> toggleFavorite(int trackId) async {
    final key = trackId.toString();
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
      return;
    }
    await _favoritesBox.put(key, true);
  }
}

