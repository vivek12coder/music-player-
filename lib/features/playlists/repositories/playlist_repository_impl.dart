import '../../../core/constants/app_constants.dart';
import '../../../core/contracts/app_contracts.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/local_storage_service.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._storageService);

  final LocalStorageService _storageService;

  @override
  Future<void> addTrack(String playlistId, int trackId) async {
    final playlist = await _getPlaylist(playlistId);
    if (playlist == null || playlist.trackIds.contains(trackId)) {
      return;
    }

    await _savePlaylist(
      playlist.copyWith(
        trackIds: [...playlist.trackIds, trackId],
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AppPlaylist> createPlaylist(String name) async {
    final now = DateTime.now();
    final playlist = AppPlaylist(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      trackIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    await _savePlaylist(playlist);
    return playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<AppPlaylist>> getPlaylists() async {
    return _box.values
        .whereType<Map>()
        .map((entry) => AppPlaylist.fromMap(entry))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> removeTrack(String playlistId, int trackId) async {
    final playlist = await _getPlaylist(playlistId);
    if (playlist == null) {
      return;
    }

    await _savePlaylist(
      playlist.copyWith(
        trackIds: playlist.trackIds.where((id) => id != trackId).toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> renamePlaylist(String id, String name) async {
    final playlist = await _getPlaylist(id);
    if (playlist == null) {
      return;
    }

    await _savePlaylist(
      playlist.copyWith(name: name, updatedAt: DateTime.now()),
    );
  }

  Future<AppPlaylist?> _getPlaylist(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) {
      return null;
    }
    return AppPlaylist.fromMap(raw);
  }

  Future<void> _savePlaylist(AppPlaylist playlist) {
    return _box.put(playlist.id, playlist.toMap());
  }

  dynamic get _box => _storageService.box(AppConstants.playlistsBox);
}

