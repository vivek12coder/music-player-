import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';

class LibraryState {
  const LibraryState({
    this.permission = PermissionAccess.unknown,
    this.allTracks = const [],
    this.tracks = const [],
    this.totalTracks = 0,
    this.albums = const [],
    this.artists = const [],
    this.query = '',
    this.sort = LibrarySort.title,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  final PermissionAccess permission;
  final List<Track> allTracks;
  final List<Track> tracks;
  final int totalTracks;
  final List<Album> albums;
  final List<Artist> artists;
  final String query;
  final LibrarySort sort;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  LibraryState copyWith({
    PermissionAccess? permission,
    List<Track>? allTracks,
    List<Track>? tracks,
    int? totalTracks,
    List<Album>? albums,
    List<Artist>? artists,
    String? query,
    LibrarySort? sort,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      permission: permission ?? this.permission,
      allTracks: allTracks ?? this.allTracks,
      tracks: tracks ?? this.tracks,
      totalTracks: totalTracks ?? this.totalTracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LibraryViewModel extends StateNotifier<LibraryState> {
  LibraryViewModel(this._ref) : super(const LibraryState()) {
    Future<void>.microtask(loadLibrary);
  }

  static const int _pageSize = 80;

  final Ref _ref;

  Future<void> loadLibrary({bool force = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    final repository = _ref.read(mediaLibraryRepositoryProvider);
    try {
      final permission = await repository.ensurePermission();
      if (permission != PermissionAccess.granted) {
        state = state.copyWith(
          permission: permission,
          isLoading: false,
          allTracks: const [],
          tracks: const [],
          totalTracks: 0,
          albums: const [],
          artists: const [],
          hasMore: false,
        );
        return;
      }

      await repository.scanLibrary(force: force);
      final allTracks = await repository.getSongs(
        query: state.query,
        sort: state.sort,
      );
      final albums = await repository.getAlbums();
      final artists = await repository.getArtists();
      final visibleTracks = allTracks.take(_pageSize).toList();

      state = state.copyWith(
        permission: permission,
        allTracks: allTracks,
        tracks: visibleTracks,
        totalTracks: allTracks.length,
        albums: albums,
        artists: artists,
        hasMore: allTracks.length > visibleTracks.length,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load your music library.',
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, error: null);
    final allTracks = await _ref.read(mediaLibraryRepositoryProvider).getSongs(
          query: query,
          sort: state.sort,
        );
    final visibleTracks = allTracks.take(_pageSize).toList();
    state = state.copyWith(
      allTracks: allTracks,
      tracks: visibleTracks,
      totalTracks: allTracks.length,
      hasMore: allTracks.length > visibleTracks.length,
      isLoading: false,
    );
  }

  Future<void> updateSort(LibrarySort sort) async {
    state = state.copyWith(sort: sort);
    await search(state.query);
  }

  void loadMore() {
    if (!state.hasMore || state.isLoading) {
      return;
    }
    final nextSize = (state.tracks.length + _pageSize).clamp(0, state.allTracks.length);
    final visibleTracks = state.allTracks.take(nextSize).toList();
    state = state.copyWith(
      tracks: visibleTracks,
      hasMore: visibleTracks.length < state.allTracks.length,
    );
  }
}

final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, LibraryState>((ref) {
  return LibraryViewModel(ref);
});

