import '../../../core/contracts/app_contracts.dart';
import '../../../core/models/app_models.dart';
import '../../../core/utils/time_of_day_segment.dart';

class SmartShuffleService implements RecommendationService {
  const SmartShuffleService();

  @override
  Future<List<RecommendationResult>> buildHomeRecommendations({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  }) async {
    if (library.isEmpty) {
      return const [];
    }

    final segment = resolveTimeSegment(DateTime.now());
    final sorted = await buildSmartShuffleQueue(
      library: library,
      stats: stats,
      favorites: favorites,
    );

    final title = switch (segment) {
      TimeOfDaySegment.morning => 'For this morning',
      TimeOfDaySegment.afternoon => 'For this afternoon',
      TimeOfDaySegment.evening => 'For this evening',
      TimeOfDaySegment.night => 'For tonight',
    };

    final mostPlayed = [...library]
      ..sort((a, b) {
        final aCount = stats[a.id]?.playCount ?? 0;
        final bCount = stats[b.id]?.playCount ?? 0;
        return bCount.compareTo(aCount);
      });

    return [
      RecommendationResult(
        title: title,
        subtitle: 'Adapted to your recent listening habits',
        tracks: sorted.take(8).map((entry) => entry.track).toList(),
      ),
      RecommendationResult(
        title: 'Because you keep playing...',
        subtitle: 'High-confidence picks from your local history',
        tracks: mostPlayed.take(8).toList(),
      ),
    ];
  }

  @override
  Future<List<PlaybackQueueItem>> buildSmartShuffleQueue({
    required List<Track> library,
    required Map<int, PlayStats> stats,
    required Set<int> favorites,
  }) async {
    final segment = resolveTimeSegment(DateTime.now());
    final ranked = library.map((track) {
      final stat = stats[track.id];
      final score = _scoreTrack(
        track: track,
        stats: stat,
        favorites: favorites,
        segment: segment,
      );
      return PlaybackQueueItem(
        track: track,
        origin: 'smart_shuffle',
        score: score,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return _diversify(ranked);
  }

  List<PlaybackQueueItem> _diversify(List<PlaybackQueueItem> ranked) {
    final remaining = [...ranked];
    final output = <PlaybackQueueItem>[];

    while (remaining.isNotEmpty) {
      final lastArtist = output.isEmpty ? null : output.last.track.artist;
      final next = remaining.firstWhere(
        (entry) => entry.track.artist != lastArtist,
        orElse: () => remaining.first,
      );
      output.add(next);
      remaining.remove(next);
    }

    return output;
  }

  double _scoreTrack({
    required Track track,
    required PlayStats? stats,
    required Set<int> favorites,
    required TimeOfDaySegment segment,
  }) {
    final playCount = (stats?.playCount ?? 0).toDouble();
    final completionRate = stats?.completionRate ?? 0;
    final skipRate = stats?.skipRate ?? 0;
    final listenRatio = stats?.averageListenRatio ?? 0;
    final favoriteBoost = favorites.contains(track.id) ? 1.4 : 0;

    final recency = stats?.lastPlayedAt == null
        ? 0.2
        : 1 / (1 + DateTime.now().difference(stats!.lastPlayedAt!).inDays);

    final segmentBoost = (stats?.segmentAffinity[segment.name] ?? 0) * 0.12;

    return (playCount * 0.28) +
        (completionRate * 2.1) +
        (listenRatio * 1.5) +
        favoriteBoost +
        recency +
        segmentBoost -
        (skipRate * 2.4);
  }
}

