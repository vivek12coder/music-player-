import 'dart:async';

import '../models/app_models.dart';

abstract class AudioPlaybackService {
  Stream<PlaybackSnapshot> get snapshotStream;

  PlaybackSnapshot get currentSnapshot;

  Future<void> setQueue(
    List<PlaybackQueueItem> queue, {
    int initialIndex = 0,
    bool autoPlay = true,
  });

  Future<void> restoreSavedQueue(List<Track> library);

  Future<void> play();

  Future<void> pause();

  Future<void> togglePlayPause();

  Future<void> skipNext();

  Future<void> skipPrevious();

  Future<void> seek(Duration position);

  Future<void> setVolume(double value);

  Future<void> setSpeed(double value);

  Future<void> setRepeatSetting(RepeatModeSetting mode);

  Future<void> toggleShuffle();

  Future<int?> getAudioSessionId();

  Future<void> updateSleepTimer(SleepTimerState state);
}

abstract class MediaLibraryRepository {
  Future<PermissionAccess> ensurePermission();

  Future<List<Track>> scanLibrary({bool force = false});

  Future<List<Track>> getSongs({
    String query = '',
    LibrarySort sort = LibrarySort.title,
  });

  Future<List<Album>> getAlbums();

  Future<List<Artist>> getArtists();

  Future<Track?> findTrackById(int id);
}

abstract class PlaylistRepository {
  Future<List<AppPlaylist>> getPlaylists();

  Future<AppPlaylist> createPlaylist(String name);

  Future<void> renamePlaylist(String id, String name);

  Future<void> deletePlaylist(String id);

  Future<void> addTrack(String playlistId, int trackId);

  Future<void> removeTrack(String playlistId, int trackId);
}

abstract class UserLibraryRepository {
  Future<Set<int>> getFavoriteIds();

  Future<List<Track>> getFavoriteTracks(List<Track> library);

  Future<void> toggleFavorite(int trackId);

  Future<List<Track>> getRecentlyPlayed(List<Track> library);

  Future<Map<int, PlayStats>> getPlayStats();

  Future<void> recordPlayEvent(PlayEvent event);

  Future<void> clearHistory();

  Future<void> saveSleepTimer(SleepTimerState state);

  Future<SleepTimerState> getSleepTimer();

  Future<void> saveEqualizerPreset(EqualizerPreset preset);

  Future<EqualizerPreset?> getEqualizerPreset();
}

abstract class PermissionService {
  Future<PermissionAccess> checkLibraryPermission();

  Future<PermissionAccess> requestLibraryPermission();

  Future<bool> openSettings();
}

abstract class EqualizerService {
  Future<bool> isSupported();

  Future<void> init(int sessionId);

  Future<List<int>> getBandLevelRange();

  Future<List<int>> getBandFrequencies();

  Future<List<int>> getBandLevels();

  Future<List<String>> getPresets();

  Future<void> setEnabled(bool enabled);

  Future<void> setBandLevel(int band, int level);

  Future<void> usePreset(int presetIndex);

  Future<void> release();
}

abstract class WaveformService {
  Future<List<double>> loadWaveform(Track track);
}

abstract class RecommendationService {
  Future<List<PlaybackQueueItem>> buildSmartShuffleQueue({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  });

  Future<List<RecommendationResult>> buildHomeRecommendations({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  });
}

