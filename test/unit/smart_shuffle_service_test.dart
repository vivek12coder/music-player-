import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/core/models/app_models.dart';
import 'package:music_player/core/utils/time_of_day_segment.dart';
import 'package:music_player/features/recommendations/services/smart_shuffle_service.dart';

void main() {
  group('SmartShuffleService', () {
    const service = SmartShuffleService();

    test('prioritizes higher affinity tracks', () async {
      const library = [
        Track(
          id: 1,
          title: 'A',
          artist: 'Atlas',
          album: 'A',
          path: '/1.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
        Track(
          id: 2,
          title: 'B',
          artist: 'Luma',
          album: 'B',
          path: '/2.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
      ];

      final queue = await service.buildSmartShuffleQueue(
        library: library,
        favorites: {1},
        stats: {
          1: const PlayStats(
            trackId: 1,
            playCount: 10,
            skipCount: 0,
            completionCount: 9,
            totalListenedMs: 1600000,
            totalDurationMs: 1800000,
          ),
          2: const PlayStats(
            trackId: 2,
            playCount: 2,
            skipCount: 2,
            completionCount: 0,
            totalListenedMs: 50000,
            totalDurationMs: 300000,
          ),
        },
      );

      expect(queue.first.track.id, 1);
    });

    test('returns a queue with all unique tracks', () async {
      const library = [
        Track(
          id: 1,
          title: 'A',
          artist: 'Atlas',
          album: 'A',
          path: '/1.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
        Track(
          id: 2,
          title: 'B',
          artist: 'Atlas',
          album: 'B',
          path: '/2.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
        Track(
          id: 3,
          title: 'C',
          artist: 'Luma',
          album: 'C',
          path: '/3.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
      ];

      final queue = await service.buildSmartShuffleQueue(
        library: library,
        favorites: const {},
        stats: const {},
      );

      expect(queue.length, library.length);
      expect(queue.map((item) => item.track.id).toSet().length, library.length);
    });

    test('builds home recommendations with at least one section', () async {
      const library = [
        Track(
          id: 1,
          title: 'A',
          artist: 'Atlas',
          album: 'A',
          path: '/1.mp3',
          durationMs: 180000,
          dateAdded: null,
        ),
      ];

      final sections = await service.buildHomeRecommendations(
        library: library,
        favorites: const {},
        stats: const {},
      );

      expect(sections, isNotEmpty);
      expect(sections.first.tracks, isNotEmpty);
    });
  });

  group('Time of day segmentation', () {
    test('maps hour ranges to expected segment', () {
      expect(resolveTimeSegment(DateTime(2026, 4, 19, 8)), TimeOfDaySegment.morning);
      expect(resolveTimeSegment(DateTime(2026, 4, 19, 14)), TimeOfDaySegment.afternoon);
      expect(resolveTimeSegment(DateTime(2026, 4, 19, 18)), TimeOfDaySegment.evening);
      expect(resolveTimeSegment(DateTime(2026, 4, 19, 2)), TimeOfDaySegment.night);
    });
  });
}

