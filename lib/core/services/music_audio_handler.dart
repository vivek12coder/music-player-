import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../constants/app_constants.dart';
import '../contracts/app_contracts.dart';
import '../logging/app_logger.dart';
import '../models/app_models.dart';
import 'local_storage_service.dart';

class MusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioPlaybackService {
  MusicAudioHandler({
    required LocalStorageService storageService,
    required AppLogger logger,
  })  : _storageService = storageService,
        _logger = logger {
    _player = AudioPlayer();
    final settings = _storageService.box(AppConstants.settingsBox);
    final savedVolume = settings.get(AppConstants.savedVolumeKey) as num?;
    final savedSpeed = settings.get(AppConstants.savedSpeedKey) as num?;
    if (savedVolume != null) {
      _player.setVolume(savedVolume.toDouble());
    }
    if (savedSpeed != null) {
      _player.setSpeed(savedSpeed.toDouble());
    }
    _bindPlayer();
  }

  late final AudioPlayer _player;
  final LocalStorageService _storageService;
  final AppLogger _logger;
  final _snapshotController = BehaviorSubject<PlaybackSnapshot>.seeded(
    PlaybackSnapshot.empty,
  );
  int _lastPersistedIndex = -1;

  PlaybackSnapshot _snapshot = PlaybackSnapshot.empty;

  @override
  PlaybackSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Future<int?> getAudioSessionId() async {
    try {
      return await _player.androidAudioSessionIdStream.first;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> restoreSavedQueue(List<Track> library) async {
    final settings = _storageService.box(AppConstants.settingsBox);
    final rawQueue = settings.get(AppConstants.savedQueueKey);
    if (rawQueue is! List || rawQueue.isEmpty) {
      return;
    }

    final trackById = {for (final track in library) track.id: track};
    final queueItems = rawQueue
        .whereType<Map>()
        .map((entry) => PlaybackQueueItem(
              track: trackById[entry['trackId'] as int] ??
                  Track.fromMap(entry['track'] as Map),
              origin: entry['origin'] as String? ?? 'restored',
              score: (entry['score'] as num?)?.toDouble() ?? 0,
            ))
        .where((entry) => entry.track.path.isNotEmpty)
        .toList();

    if (queueItems.isEmpty) {
      return;
    }

    await setQueue(
      queueItems,
      initialIndex: settings.get(AppConstants.savedQueueIndexKey) as int? ?? 0,
      autoPlay: false,
    );
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setQueue(
    List<PlaybackQueueItem> items, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    if (items.isEmpty) {
      return;
    }

    final queueItems = items
        .where((item) => item.track.path.isNotEmpty && File(item.track.path).existsSync())
        .toList();
    if (queueItems.isEmpty) {
      _logger.warning('No playable files found in queue request.');
      return;
    }

    final safeIndex = initialIndex.clamp(0, queueItems.length - 1);
    final children = queueItems.map((item) {
      return AudioSource.file(
        item.track.path,
        tag: MediaItem(
          id: item.track.id.toString(),
          title: item.track.titleOrFallback,
          artist: item.track.artistOrFallback,
          album: item.track.albumOrFallback,
          duration: item.track.duration,
          extras: {'path': item.track.path},
        ),
      );
    }).toList();

    await _player.setAudioSources(
      children,
      initialIndex: safeIndex,
    );
    queue.add(children.map((entry) => entry.tag! as MediaItem).toList());
    _snapshot = _snapshot.copyWith(
      queue: queueItems,
      currentIndex: safeIndex,
      duration: queueItems[safeIndex].track.duration,
    );
    await _persistQueue(queueItems, safeIndex);
    _lastPersistedIndex = safeIndex;
    _emitSnapshot();
    if (autoPlay) {
      await _player.play();
    }
  }

  @override
  Future<void> setRepeatSetting(RepeatModeSetting mode) async {
    await _player.setLoopMode(
      switch (mode) {
        RepeatModeSetting.off => LoopMode.off,
        RepeatModeSetting.all => LoopMode.all,
        RepeatModeSetting.one => LoopMode.one,
      },
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await setRepeatSetting(
      switch (repeatMode) {
        AudioServiceRepeatMode.none => RepeatModeSetting.off,
        AudioServiceRepeatMode.all => RepeatModeSetting.all,
        AudioServiceRepeatMode.one => RepeatModeSetting.one,
        AudioServiceRepeatMode.group => RepeatModeSetting.all,
      },
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    await _storageService
        .box(AppConstants.settingsBox)
        .put(AppConstants.savedSpeedKey, speed);
  }

  @override
  Future<void> setVolume(double value) async {
    await _player.setVolume(value);
    await _storageService
        .box(AppConstants.settingsBox)
        .put(AppConstants.savedVolumeKey, value);
  }

  @override
  Future<void> skipNext() => _player.seekToNext();

  @override
  Future<void> skipPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToNext() => skipNext();

  @override
  Future<void> skipToPrevious() => skipPrevious();

  @override
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
      return;
    }
    await play();
  }

  @override
  Future<void> toggleShuffle() async {
    final nextValue = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(nextValue);
    if (nextValue) {
      await _player.shuffle();
    }
  }

  @override
  Future<void> updateSleepTimer(SleepTimerState state) async {
    _snapshot = _snapshot.copyWith(sleepTimerState: state);
    _emitSnapshot();
  }

  void _bindPlayer() {
    _player.playerStateStream.listen((playerState) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: playerState.playing,
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[playerState.processingState]!,
          controls: [
            MediaControl.skipToPrevious,
            if (playerState.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
        ),
      );
      _syncSnapshot();
    });

    Rx.combineLatest4<Duration, Duration, int?, double,
        Map<String, dynamic>>(
      _player.positionStream,
      _player.bufferedPositionStream,
      _player.currentIndexStream,
      _player.speedStream,
      (position, buffered, currentIndex, speed) {
        return {
          'position': position,
          'buffered': buffered,
          'index': currentIndex ?? _player.currentIndex ?? -1,
          'speed': speed,
        };
      },
    ).listen((state) async {
      final index = state['index'] as int;
      if (index >= 0 && index < _snapshot.queue.length) {
        final previousIndex = _snapshot.currentIndex;
        _snapshot = _snapshot.copyWith(
          currentIndex: index,
          position: state['position'] as Duration,
          bufferedPosition: state['buffered'] as Duration,
          duration: _snapshot.queue[index].track.duration,
          speed: state['speed'] as double,
          volume: _player.volume,
          shuffleEnabled: _player.shuffleModeEnabled,
          repeatMode: switch (_player.loopMode) {
            LoopMode.off => RepeatModeSetting.off,
            LoopMode.all => RepeatModeSetting.all,
            LoopMode.one => RepeatModeSetting.one,
          },
        );
        if (index < queue.value.length) {
          mediaItem.add(queue.value[index]);
        }
        if (index != previousIndex || _lastPersistedIndex != index) {
          await _persistQueue(_snapshot.queue, index);
          _lastPersistedIndex = index;
        }
        _emitSnapshot();
      }
    });
  }

  void _emitSnapshot() {
    _snapshotController.add(_snapshot);
  }

  Future<void> _persistQueue(List<PlaybackQueueItem> queue, int index) async {
    final settings = _storageService.box(AppConstants.settingsBox);
    await settings.put(
      AppConstants.savedQueueKey,
      queue
          .map((item) => {
                'trackId': item.track.id,
                'track': item.track.toMap(),
                'origin': item.origin,
                'score': item.score,
              })
          .toList(),
    );
    await settings.put(AppConstants.savedQueueIndexKey, index);
  }

  void _syncSnapshot() {
    _snapshot = _snapshot.copyWith(
      isPlaying: _player.playing,
      isBuffering: _player.processingState == ProcessingState.buffering,
      repeatMode: switch (_player.loopMode) {
        LoopMode.off => RepeatModeSetting.off,
        LoopMode.all => RepeatModeSetting.all,
        LoopMode.one => RepeatModeSetting.one,
      },
      shuffleEnabled: _player.shuffleModeEnabled,
      volume: _player.volume,
      speed: _player.speed,
    );
    _emitSnapshot();
  }
}
