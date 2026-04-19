import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';

class PlaylistsState {
  const PlaylistsState({
    this.playlists = const [],
    this.selectedPlaylistId,
    this.isLoading = false,
    this.error,
  });

  final List<AppPlaylist> playlists;
  final String? selectedPlaylistId;
  final bool isLoading;
  final String? error;

  PlaylistsState copyWith({
    List<AppPlaylist>? playlists,
    String? selectedPlaylistId,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      selectedPlaylistId: selectedPlaylistId ?? this.selectedPlaylistId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PlaylistsViewModel extends StateNotifier<PlaylistsState> {
  PlaylistsViewModel(this._ref) : super(const PlaylistsState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> addTrack(String playlistId, int trackId) async {
    await _ref.read(playlistRepositoryProvider).addTrack(playlistId, trackId);
    await load();
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _ref.read(playlistRepositoryProvider).createPlaylist(name.trim());
    await load();
  }

  Future<void> deletePlaylist(String id) async {
    await _ref.read(playlistRepositoryProvider).deletePlaylist(id);
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final playlists = await _ref.read(playlistRepositoryProvider).getPlaylists();
      state = state.copyWith(playlists: playlists, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Playlists could not be loaded.',
      );
    }
  }

  Future<void> removeTrack(String playlistId, int trackId) async {
    await _ref.read(playlistRepositoryProvider).removeTrack(playlistId, trackId);
    await load();
  }

  Future<void> renamePlaylist(String id, String name) async {
    await _ref.read(playlistRepositoryProvider).renamePlaylist(id, name.trim());
    await load();
  }

  void selectPlaylist(String? id) {
    state = state.copyWith(selectedPlaylistId: id);
  }
}

final playlistsViewModelProvider =
    StateNotifierProvider<PlaylistsViewModel, PlaylistsState>((ref) {
  return PlaylistsViewModel(ref);
});

