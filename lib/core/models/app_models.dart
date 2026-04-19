import 'dart:math';

import '../utils/time_of_day_segment.dart';

enum PermissionAccess {
  unknown,
  granted,
  denied,
  permanentlyDenied,
}

enum LibrarySort {
  title,
  artist,
  album,
  duration,
}

enum RepeatModeSetting {
  off,
  all,
  one,
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.durationMs,
    required this.dateAdded,
    this.albumId,
    this.artistId,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int durationMs;
  final DateTime? dateAdded;
  final int? albumId;
  final int? artistId;

  factory Track.fromMap(Map<dynamic, dynamic> map) {
    return Track(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      album: map['album'] as String? ?? '',
      path: map['path'] as String? ?? '',
      durationMs: map['durationMs'] as int? ?? 0,
      dateAdded: map['dateAdded'] == null
          ? null
          : DateTime.tryParse(map['dateAdded'] as String),
      albumId: map['albumId'] as int?,
      artistId: map['artistId'] as int?,
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);

  String get titleOrFallback => title.trim().isEmpty ? 'Unknown title' : title;

  String get artistOrFallback => artist.trim().isEmpty ? 'Unknown artist' : artist;

  String get albumOrFallback => album.trim().isEmpty ? 'Unknown album' : album;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'durationMs': durationMs,
      'dateAdded': dateAdded?.toIso8601String(),
      'albumId': albumId,
      'artistId': artistId,
    };
  }

}

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.trackCount,
    this.artworkTrackId,
  });

  final int id;
  final String title;
  final String artist;
  final int trackCount;
  final int? artworkTrackId;
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.trackCount,
  });

  final int id;
  final String name;
  final int trackCount;
}

class AppPlaylist {
  const AppPlaylist({
    required this.id,
    required this.name,
    required this.trackIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<int> trackIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppPlaylist.fromMap(Map<dynamic, dynamic> map) {
    return AppPlaylist(
      id: map['id'] as String,
      name: map['name'] as String,
      trackIds: (map['trackIds'] as List<dynamic>).cast<int>(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  AppPlaylist copyWith({
    String? name,
    List<int>? trackIds,
    DateTime? updatedAt,
  }) {
    return AppPlaylist(
      id: id,
      name: name ?? this.name,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'trackIds': trackIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

}

class PlaybackQueueItem {
  const PlaybackQueueItem({
    required this.track,
    required this.origin,
    this.score = 0,
  });

  final Track track;
  final String origin;
  final double score;
}

class SleepTimerState {
  const SleepTimerState({
    required this.isActive,
    this.endsAt,
  });

  final bool isActive;
  final DateTime? endsAt;

  factory SleepTimerState.fromMap(Map<dynamic, dynamic> map) {
    return SleepTimerState(
      isActive: map['isActive'] as bool? ?? false,
      endsAt: map['endsAt'] == null
          ? null
          : DateTime.tryParse(map['endsAt'] as String),
    );
  }

  Duration get remaining {
    if (endsAt == null) {
      return Duration.zero;
    }
    final diff = endsAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'endsAt': endsAt?.toIso8601String(),
    };
  }

}

class EqualizerPreset {
  const EqualizerPreset({
    required this.name,
    required this.bandLevels,
    this.enabled = false,
  });

  final String name;
  final List<int> bandLevels;
  final bool enabled;

  factory EqualizerPreset.fromMap(Map<dynamic, dynamic> map) {
    return EqualizerPreset(
      name: map['name'] as String,
      bandLevels: (map['bandLevels'] as List<dynamic>).cast<int>(),
      enabled: map['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bandLevels': bandLevels,
      'enabled': enabled,
    };
  }

}

class PlayStats {
  const PlayStats({
    required this.trackId,
    required this.playCount,
    required this.skipCount,
    required this.completionCount,
    this.lastPlayedAt,
    this.totalListenedMs = 0,
    this.totalDurationMs = 0,
    this.segmentAffinity = const {},
  });

  final int trackId;
  final int playCount;
  final int skipCount;
  final int completionCount;
  final DateTime? lastPlayedAt;
  final int totalListenedMs;
  final int totalDurationMs;
  final Map<String, int> segmentAffinity;

  factory PlayStats.fromMap(Map<dynamic, dynamic> map) {
    return PlayStats(
      trackId: map['trackId'] as int,
      playCount: map['playCount'] as int? ?? 0,
      skipCount: map['skipCount'] as int? ?? 0,
      completionCount: map['completionCount'] as int? ?? 0,
      lastPlayedAt: map['lastPlayedAt'] == null
          ? null
          : DateTime.tryParse(map['lastPlayedAt'] as String),
      totalListenedMs: map['totalListenedMs'] as int? ?? 0,
      totalDurationMs: map['totalDurationMs'] as int? ?? 0,
      segmentAffinity: (map['segmentAffinity'] as Map<dynamic, dynamic>? ?? {})
          .map((key, value) => MapEntry(key.toString(), value as int)),
    );
  }

  double get completionRate {
    if (playCount == 0) {
      return 0;
    }
    return completionCount / playCount;
  }

  double get skipRate {
    if (playCount == 0) {
      return 0;
    }
    return skipCount / playCount;
  }

  double get averageListenRatio {
    if (totalDurationMs == 0) {
      return 0;
    }
    return min(1, totalListenedMs / totalDurationMs);
  }

  PlayStats registerPlay({
    required Duration listened,
    required Duration duration,
    required bool completed,
    required bool skipped,
    required TimeOfDaySegment segment,
  }) {
    final nextAffinity = Map<String, int>.from(segmentAffinity);
    nextAffinity.update(segment.name, (value) => value + 1, ifAbsent: () => 1);
    return PlayStats(
      trackId: trackId,
      playCount: playCount + 1,
      skipCount: skipCount + (skipped ? 1 : 0),
      completionCount: completionCount + (completed ? 1 : 0),
      lastPlayedAt: DateTime.now(),
      totalListenedMs: totalListenedMs + listened.inMilliseconds,
      totalDurationMs: totalDurationMs + duration.inMilliseconds,
      segmentAffinity: nextAffinity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'playCount': playCount,
      'skipCount': skipCount,
      'completionCount': completionCount,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'totalListenedMs': totalListenedMs,
      'totalDurationMs': totalDurationMs,
      'segmentAffinity': segmentAffinity,
    };
  }

  static const empty = PlayStats(
    trackId: -1,
    playCount: 0,
    skipCount: 0,
    completionCount: 0,
  );
}

class PlayEvent {
  const PlayEvent({
    required this.trackId,
    required this.listened,
    required this.duration,
    required this.completed,
    required this.skipped,
  });

  final int trackId;
  final Duration listened;
  final Duration duration;
  final bool completed;
  final bool skipped;
}

class RecommendationResult {
  const RecommendationResult({
    required this.title,
    required this.subtitle,
    required this.tracks,
  });

  final String title;
  final String subtitle;
  final List<Track> tracks;
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
    required this.isPlaying,
    required this.isBuffering,
    required this.volume,
    required this.speed,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.sleepTimerState,
  });

  final List<PlaybackQueueItem> queue;
  final int currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final double speed;
  final bool shuffleEnabled;
  final RepeatModeSetting repeatMode;
  final SleepTimerState sleepTimerState;

  Track? get currentTrack {
    if (currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
    return queue[currentIndex].track;
  }

  PlaybackSnapshot copyWith({
    List<PlaybackQueueItem>? queue,
    int? currentIndex,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? speed,
    bool? shuffleEnabled,
    RepeatModeSetting? repeatMode,
    SleepTimerState? sleepTimerState,
  }) {
    return PlaybackSnapshot(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      sleepTimerState: sleepTimerState ?? this.sleepTimerState,
    );
  }

  static const empty = PlaybackSnapshot(
    queue: [],
    currentIndex: -1,
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: Duration.zero,
    isPlaying: false,
    isBuffering: false,
    volume: 1,
    speed: 1,
    shuffleEnabled: false,
    repeatMode: RepeatModeSetting.off,
    sleepTimerState: SleepTimerState(isActive: false),
  );
}

