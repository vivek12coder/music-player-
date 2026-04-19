import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:music_player/core/contracts/app_contracts.dart';
import 'package:music_player/core/models/app_models.dart';

class FakeAudioPlaybackService implements AudioPlaybackService {
  final _controller = StreamController<PlaybackSnapshot>.broadcast();
  PlaybackSnapshot _snapshot = PlaybackSnapshot.empty;

  @override
  PlaybackSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => _controller.stream;

  @override
  Future<int?> getAudioSessionId() async => 1;

  @override
  Future<void> pause() async {
    _snapshot = _snapshot.copyWith(isPlaying: false);
    _controller.add(_snapshot);
  }

  @override
  Future<void> play() async {
    _snapshot = _snapshot.copyWith(isPlaying: true);
    _controller.add(_snapshot);
  }

  @override
  Future<void> restoreSavedQueue(List<Track> library) async {}

  @override
  Future<void> seek(Duration position) async {
    _snapshot = _snapshot.copyWith(position: position);
    _controller.add(_snapshot);
  }

  @override
  Future<void> setQueue(
    List<PlaybackQueueItem> queue, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    _snapshot = PlaybackSnapshot.empty.copyWith(
      queue: queue,
      currentIndex: initialIndex,
      duration: queue.isEmpty ? Duration.zero : queue[initialIndex].track.duration,
      isPlaying: autoPlay,
    );
    _controller.add(_snapshot);
  }

  @override
  Future<void> setRepeatSetting(RepeatModeSetting mode) async {
    _snapshot = _snapshot.copyWith(repeatMode: mode);
    _controller.add(_snapshot);
  }

  @override
  Future<void> setSpeed(double value) async {
    _snapshot = _snapshot.copyWith(speed: value);
    _controller.add(_snapshot);
  }

  @override
  Future<void> setVolume(double value) async {
    _snapshot = _snapshot.copyWith(volume: value);
    _controller.add(_snapshot);
  }

  @override
  Future<void> skipNext() async {
    if (_snapshot.currentIndex + 1 < _snapshot.queue.length) {
      _snapshot = _snapshot.copyWith(currentIndex: _snapshot.currentIndex + 1);
      _controller.add(_snapshot);
    }
  }

  @override
  Future<void> skipPrevious() async {
    if (_snapshot.currentIndex > 0) {
      _snapshot = _snapshot.copyWith(currentIndex: _snapshot.currentIndex - 1);
      _controller.add(_snapshot);
    }
  }

  @override
  Future<void> togglePlayPause() async {
    _snapshot = _snapshot.copyWith(isPlaying: !_snapshot.isPlaying);
    _controller.add(_snapshot);
  }

  @override
  Future<void> toggleShuffle() async {
    _snapshot = _snapshot.copyWith(shuffleEnabled: !_snapshot.shuffleEnabled);
    _controller.add(_snapshot);
  }

  @override
  Future<void> updateSleepTimer(SleepTimerState state) async {
    _snapshot = _snapshot.copyWith(sleepTimerState: state);
    _controller.add(_snapshot);
  }
}

class FakeMediaLibraryRepository implements MediaLibraryRepository {
  FakeMediaLibraryRepository([List<Track>? library])
      : _library = library ??
            const [
              Track(
                id: 1,
                title: 'Neon Skyline',
                artist: 'Atlas',
                album: 'Midnight Drive',
                path: '/music/1.mp3',
                durationMs: 240000,
                dateAdded: null,
              ),
              Track(
                id: 2,
                title: 'Soft Focus',
                artist: 'Luma',
                album: 'Afterglow',
                path: '/music/2.mp3',
                durationMs: 180000,
                dateAdded: null,
              ),
            ];

  final List<Track> _library;

  @override
  Future<PermissionAccess> ensurePermission() async => PermissionAccess.granted;

  @override
  Future<Track?> findTrackById(int id) async {
    for (final track in _library) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  @override
  Future<List<Album>> getAlbums() async => const [
        Album(id: 1, title: 'Midnight Drive', artist: 'Atlas', trackCount: 1),
        Album(id: 2, title: 'Afterglow', artist: 'Luma', trackCount: 1),
      ];

  @override
  Future<List<Artist>> getArtists() async => const [
        Artist(id: 1, name: 'Atlas', trackCount: 1),
        Artist(id: 2, name: 'Luma', trackCount: 1),
      ];

  @override
  Future<List<Track>> getSongs({
    String query = '',
    LibrarySort sort = LibrarySort.title,
  }) async {
    final filtered = query.isEmpty
        ? [..._library]
        : _library.where((track) => track.title.toLowerCase().contains(query.toLowerCase())).toList();
    return filtered;
  }

  @override
  Future<List<Track>> scanLibrary({bool force = false}) async => _library;
}

class FakePlaylistRepository implements PlaylistRepository {
  final List<AppPlaylist> _playlists = [];

  @override
  Future<void> addTrack(String playlistId, int trackId) async {}

  @override
  Future<AppPlaylist> createPlaylist(String name) async {
    final playlist = AppPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      trackIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _playlists.add(playlist);
    return playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
  }

  @override
  Future<List<AppPlaylist>> getPlaylists() async => [..._playlists];

  @override
  Future<void> removeTrack(String playlistId, int trackId) async {}

  @override
  Future<void> renamePlaylist(String id, String name) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index >= 0) {
      _playlists[index] = _playlists[index].copyWith(name: name);
    }
  }
}

class FakeUserLibraryRepository implements UserLibraryRepository {
  Set<int> favoriteIds = <int>{1};
  final Map<int, PlayStats> stats = {
    1: const PlayStats(
      trackId: 1,
      playCount: 8,
      skipCount: 1,
      completionCount: 6,
      totalListenedMs: 800000,
      totalDurationMs: 1200000,
      segmentAffinity: {'evening': 4},
    ),
  };
  final List<int> recentIds = [1];
  SleepTimerState sleepTimerState = const SleepTimerState(isActive: false);

  @override
  Future<void> clearHistory() async {
    recentIds.clear();
    stats.clear();
  }

  @override
  Future<EqualizerPreset?> getEqualizerPreset() async => null;

  @override
  Future<Set<int>> getFavoriteIds() async => favoriteIds;

  @override
  Future<List<Track>> getFavoriteTracks(List<Track> library) async {
    return library.where((track) => favoriteIds.contains(track.id)).toList();
  }

  @override
  Future<Map<int, PlayStats>> getPlayStats() async => stats;

  @override
  Future<List<Track>> getRecentlyPlayed(List<Track> library) async {
    return library.where((track) => recentIds.contains(track.id)).toList();
  }

  @override
  Future<SleepTimerState> getSleepTimer() async => sleepTimerState;

  @override
  Future<void> recordPlayEvent(PlayEvent event) async {}

  @override
  Future<void> saveEqualizerPreset(EqualizerPreset preset) async {}

  @override
  Future<void> saveSleepTimer(SleepTimerState state) async {
    sleepTimerState = state;
  }

  @override
  Future<void> toggleFavorite(int trackId) async {
    if (favoriteIds.contains(trackId)) {
      favoriteIds.remove(trackId);
    } else {
      favoriteIds.add(trackId);
    }
  }
}

class FakePermissionService implements PermissionService {
  @override
  Future<PermissionAccess> checkLibraryPermission() async => PermissionAccess.granted;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<PermissionAccess> requestLibraryPermission() async =>
      PermissionAccess.granted;
}

class FakeEqualizerService implements EqualizerService {
  @override
  Future<List<int>> getBandFrequencies() async => [60, 230, 910];

  @override
  Future<List<int>> getBandLevelRange() async => [-1500, 1500];

  @override
  Future<List<int>> getBandLevels() async => [0, 0, 0];

  @override
  Future<List<String>> getPresets() async => ['Flat', 'Bass boost'];

  @override
  Future<void> init(int sessionId) async {}

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> release() async {}

  @override
  Future<void> setBandLevel(int band, int level) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> usePreset(int presetIndex) async {}
}

class FakeWaveformService implements WaveformService {
  @override
  Future<List<double>> loadWaveform(Track track) async {
    return List<double>.generate(24, (index) => index.isEven ? 0.8 : 0.4);
  }
}

class FakeRecommendationService implements RecommendationService {
  @override
  Future<List<RecommendationResult>> buildHomeRecommendations({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  }) async {
    return [
      RecommendationResult(
        title: 'For this evening',
        subtitle: 'Local picks',
        tracks: library,
      ),
    ];
  }

  @override
  Future<List<PlaybackQueueItem>> buildSmartShuffleQueue({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  }) async {
    return library
        .map((track) => PlaybackQueueItem(track: track, origin: 'smart_shuffle'))
        .toList();
  }
}

class FakeAudioHandler extends BaseAudioHandler {}

