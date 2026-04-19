import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../home/viewmodels/home_viewmodel.dart';

class PlayerState {
  const PlayerState({
    this.snapshot = PlaybackSnapshot.empty,
    this.waveform = const [],
    this.equalizerPreset,
    this.equalizerEnabled = false,
    this.equalizerSupported = false,
    this.bandLevels = const [],
    this.bandRange = const [-1500, 1500],
    this.bandFrequencies = const [],
    this.presets = const [],
    this.error,
  });

  final PlaybackSnapshot snapshot;
  final List<double> waveform;
  final EqualizerPreset? equalizerPreset;
  final bool equalizerEnabled;
  final bool equalizerSupported;
  final List<int> bandLevels;
  final List<int> bandRange;
  final List<int> bandFrequencies;
  final List<String> presets;
  final String? error;

  PlayerState copyWith({
    PlaybackSnapshot? snapshot,
    List<double>? waveform,
    EqualizerPreset? equalizerPreset,
    bool? equalizerEnabled,
    bool? equalizerSupported,
    List<int>? bandLevels,
    List<int>? bandRange,
    List<int>? bandFrequencies,
    List<String>? presets,
    String? error,
  }) {
    return PlayerState(
      snapshot: snapshot ?? this.snapshot,
      waveform: waveform ?? this.waveform,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerSupported: equalizerSupported ?? this.equalizerSupported,
      bandLevels: bandLevels ?? this.bandLevels,
      bandRange: bandRange ?? this.bandRange,
      bandFrequencies: bandFrequencies ?? this.bandFrequencies,
      presets: presets ?? this.presets,
      error: error,
    );
  }
}

class PlayerViewModel extends StateNotifier<PlayerState> {
  PlayerViewModel(this._ref) : super(const PlayerState()) {
    _bootstrap();
  }

  final Ref _ref;
  StreamSubscription<PlaybackSnapshot>? _subscription;
  Timer? _sleepTimer;
  Track? _lastTrack;
  int? _waveformTrackId;
  int _waveformRequestId = 0;
  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;

  Future<void> _bootstrap() async {
    final audioService = _ref.read(audioPlaybackServiceProvider);
    _subscription = audioService.snapshotStream.listen(_onSnapshot);
    await _restorePlayback();
    await _initEqualizer();
    await _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final preset = await _ref.read(userLibraryRepositoryProvider).getEqualizerPreset();
    if (preset == null) {
      return;
    }
    state = state.copyWith(
      equalizerPreset: preset,
      equalizerEnabled: preset.enabled,
      bandLevels: preset.bandLevels,
    );
    if (state.equalizerSupported) {
      await _ref.read(equalizerServiceProvider).setEnabled(preset.enabled);
    }
  }

  Future<void> _initEqualizer() async {
    final equalizerService = _ref.read(equalizerServiceProvider);
    final supported = await equalizerService.isSupported();
    if (!supported) {
      state = state.copyWith(equalizerSupported: false);
      return;
    }

    state = state.copyWith(equalizerSupported: true);
    final sessionId = await _ref.read(audioPlaybackServiceProvider).getAudioSessionId();
    if (sessionId != null) {
      await equalizerService.init(sessionId);
      state = state.copyWith(
        bandRange: await equalizerService.getBandLevelRange(),
        bandLevels: await equalizerService.getBandLevels(),
        bandFrequencies: await equalizerService.getBandFrequencies(),
        presets: await equalizerService.getPresets(),
      );
    }
  }

  void _onSnapshot(PlaybackSnapshot snapshot) {
    _recordPlaybackTransition(snapshot);
    state = state.copyWith(snapshot: snapshot);

    final track = snapshot.currentTrack;
    if (track == null) {
      _waveformTrackId = null;
      return;
    }

    if (_waveformTrackId == track.id) {
      return;
    }

    _waveformTrackId = track.id;
    final requestId = ++_waveformRequestId;
    state = state.copyWith(waveform: const []);

    Future<void>.microtask(() async {
      final waveform = await _ref.read(waveformServiceProvider).loadWaveform(track);
      final isStale = requestId != _waveformRequestId;
      final currentTrackId = state.snapshot.currentTrack?.id;
      if (isStale || currentTrackId != track.id) {
        return;
      }
      state = state.copyWith(waveform: waveform);
    });
  }

  void _recordPlaybackTransition(PlaybackSnapshot snapshot) {
    final current = snapshot.currentTrack;
    if (_lastTrack != null && current?.id != _lastTrack?.id) {
      final completionThreshold = _lastDuration.inMilliseconds * 0.85;
      final skipThreshold = _lastDuration.inMilliseconds * 0.35;
      final listenedMs = _lastPosition.inMilliseconds;
      unawaited(
        _ref.read(userLibraryRepositoryProvider).recordPlayEvent(
              PlayEvent(
                trackId: _lastTrack!.id,
                listened: _lastPosition,
                duration: _lastDuration,
                completed: listenedMs >= completionThreshold,
                skipped: listenedMs > 0 && listenedMs < skipThreshold,
              ),
            ),
      );
    }

    _lastTrack = current;
    _lastPosition = snapshot.position;
    _lastDuration = snapshot.duration;
  }

  Future<void> _restorePlayback() async {
    final library = await _ref.read(mediaLibraryRepositoryProvider).scanLibrary();
    await _ref.read(audioPlaybackServiceProvider).restoreSavedQueue(library);
    final sleepTimer = await _ref.read(userLibraryRepositoryProvider).getSleepTimer();
    if (sleepTimer.isActive && sleepTimer.endsAt != null) {
      await startSleepTimer(sleepTimer.remaining);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _subscription?.cancel();
    if (state.equalizerSupported) {
      unawaited(_ref.read(equalizerServiceProvider).release());
    }
    super.dispose();
  }

  Future<void> next() => _ref.read(audioPlaybackServiceProvider).skipNext();

  Future<void> previous() => _ref.read(audioPlaybackServiceProvider).skipPrevious();

  Future<void> seek(Duration value) =>
      _ref.read(audioPlaybackServiceProvider).seek(value);

  Future<void> setRepeatMode(RepeatModeSetting mode) =>
      _ref.read(audioPlaybackServiceProvider).setRepeatSetting(mode);

  Future<void> setSpeed(double value) =>
      _ref.read(audioPlaybackServiceProvider).setSpeed(value);

  Future<void> setVolume(double value) =>
      _ref.read(audioPlaybackServiceProvider).setVolume(value);

  Future<void> startSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    final stateValue = SleepTimerState(
      isActive: true,
      endsAt: DateTime.now().add(duration),
    );
    await _ref.read(audioPlaybackServiceProvider).updateSleepTimer(stateValue);
    await _ref.read(userLibraryRepositoryProvider).saveSleepTimer(stateValue);
    _sleepTimer = Timer(duration, () async {
      await _ref.read(audioPlaybackServiceProvider).pause();
      await stopSleepTimer();
    });
  }

  Future<void> stopSleepTimer() async {
    _sleepTimer?.cancel();
    const stateValue = SleepTimerState(isActive: false);
    await _ref.read(audioPlaybackServiceProvider).updateSleepTimer(stateValue);
    await _ref.read(userLibraryRepositoryProvider).saveSleepTimer(stateValue);
  }

  Future<void> toggleFavorite() async {
    final trackId = state.snapshot.currentTrack?.id;
    if (trackId == null) {
      return;
    }
    await _ref.read(userLibraryRepositoryProvider).toggleFavorite(trackId);
    _ref.invalidate(homeViewModelProvider);
  }

  Future<void> togglePlayPause() =>
      _ref.read(audioPlaybackServiceProvider).togglePlayPause();

  Future<void> toggleShuffle() =>
      _ref.read(audioPlaybackServiceProvider).toggleShuffle();

  Future<void> updateBand(int band, int level) async {
    final service = _ref.read(equalizerServiceProvider);
    await service.setBandLevel(band, level);
    final nextLevels = [...state.bandLevels]..[band] = level;
    final preset = EqualizerPreset(
      name: 'Custom',
      bandLevels: nextLevels,
      enabled: true,
    );
    await _ref.read(userLibraryRepositoryProvider).saveEqualizerPreset(preset);
    state = state.copyWith(
      bandLevels: nextLevels,
      equalizerPreset: preset,
      equalizerEnabled: true,
    );
  }

  Future<void> usePreset(int index) async {
    final service = _ref.read(equalizerServiceProvider);
    await service.usePreset(index);
    final levels = await service.getBandLevels();
    final presetName = state.presets[index];
    final preset = EqualizerPreset(
      name: presetName,
      bandLevels: levels,
      enabled: true,
    );
    await _ref.read(userLibraryRepositoryProvider).saveEqualizerPreset(preset);
    state = state.copyWith(
      bandLevels: levels,
      equalizerPreset: preset,
      equalizerEnabled: true,
    );
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    if (!state.equalizerSupported) {
      return;
    }
    await _ref.read(equalizerServiceProvider).setEnabled(enabled);
    final preset = EqualizerPreset(
      name: state.equalizerPreset?.name ?? 'Custom',
      bandLevels: state.bandLevels,
      enabled: enabled,
    );
    await _ref.read(userLibraryRepositoryProvider).saveEqualizerPreset(preset);
    state = state.copyWith(equalizerEnabled: enabled, equalizerPreset: preset);
  }
}

final playerViewModelProvider =
    StateNotifierProvider<PlayerViewModel, PlayerState>((ref) {
  return PlayerViewModel(ref);
});
