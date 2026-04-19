import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';

class HomeState {
  const HomeState({
    this.recommendations = const [],
    this.recentlyPlayed = const [],
    this.favorites = const [],
    this.favoriteIds = const <int>{},
    this.isLoading = false,
    this.error,
  });

  final List<RecommendationResult> recommendations;
  final List<Track> recentlyPlayed;
  final List<Track> favorites;
  final Set<int> favoriteIds;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    List<RecommendationResult>? recommendations,
    List<Track>? recentlyPlayed,
    List<Track>? favorites,
    Set<int>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      recommendations: recommendations ?? this.recommendations,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._ref) : super(const HomeState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final library = await _ref.read(mediaLibraryRepositoryProvider).scanLibrary();
      final userRepo = _ref.read(userLibraryRepositoryProvider);
      final stats = await userRepo.getPlayStats();
      final favorites = await userRepo.getFavoriteIds();

      final recommendationSections =
          await _ref.read(recommendationServiceProvider).buildHomeRecommendations(
                library: library,
                stats: stats,
                favorites: favorites,
              );

      state = state.copyWith(
        recommendations: recommendationSections,
        recentlyPlayed: await userRepo.getRecentlyPlayed(library),
        favorites: await userRepo.getFavoriteTracks(library),
        favoriteIds: favorites,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Home recommendations could not be loaded.',
      );
    }
  }

  Future<void> playSmartShuffle() async {
    final library = await _ref.read(mediaLibraryRepositoryProvider).scanLibrary();
    final userRepo = _ref.read(userLibraryRepositoryProvider);
    final queue = await _ref.read(recommendationServiceProvider).buildSmartShuffleQueue(
          library: library,
          stats: await userRepo.getPlayStats(),
          favorites: await userRepo.getFavoriteIds(),
        );
    await _ref.read(audioPlaybackServiceProvider).setQueue(queue);
  }

  Future<void> playTrack(Track track, List<Track> contextTracks) async {
    final queue = contextTracks
        .map((item) => PlaybackQueueItem(track: item, origin: 'library'))
        .toList();
    final index = contextTracks.indexWhere((item) => item.id == track.id);
    await _ref.read(audioPlaybackServiceProvider).setQueue(
          queue,
          initialIndex: index < 0 ? 0 : index,
        );
  }

  Future<void> toggleFavorite(int trackId) async {
    await _ref.read(userLibraryRepositoryProvider).toggleFavorite(trackId);
    await load();
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref);
});

