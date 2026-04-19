import 'package:on_audio_query/on_audio_query.dart';

import '../../../core/contracts/app_contracts.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/models/app_models.dart';

class MediaLibraryRepositoryImpl implements MediaLibraryRepository {
  MediaLibraryRepositoryImpl(
    this._permissionService,
    this._logger,
  );

  final PermissionService _permissionService;
  final AppLogger _logger;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Track> _cache = const [];

  @override
  Future<PermissionAccess> ensurePermission() async {
    final current = await _permissionService.checkLibraryPermission();
    if (current == PermissionAccess.granted) {
      return current;
    }
    return _permissionService.requestLibraryPermission();
  }

  @override
  Future<Track?> findTrackById(int id) async {
    final library = _cache.isNotEmpty ? _cache : await scanLibrary();
    for (final track in library) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  @override
  Future<List<Album>> getAlbums() async {
    final tracks = _cache.isNotEmpty ? _cache : await scanLibrary();
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      grouped.putIfAbsent(track.albumOrFallback, () => []).add(track);
    }

    return grouped.entries.map((entry) {
      final first = entry.value.first;
      return Album(
        id: first.albumId ?? entry.key.hashCode,
        title: entry.key,
        artist: first.artistOrFallback,
        trackCount: entry.value.length,
        artworkTrackId: first.id,
      );
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<List<Artist>> getArtists() async {
    final tracks = _cache.isNotEmpty ? _cache : await scanLibrary();
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      grouped.putIfAbsent(track.artistOrFallback, () => []).add(track);
    }

    return grouped.entries.map((entry) {
      return Artist(
        id: entry.key.hashCode,
        name: entry.key,
        trackCount: entry.value.length,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Track>> getSongs({
    String query = '',
    LibrarySort sort = LibrarySort.title,
  }) async {
    final library = _cache.isNotEmpty ? _cache : await scanLibrary();
    final normalized = query.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? [...library]
        : library.where((track) {
            final haystack = [
              track.title,
              track.artist,
              track.album,
            ].join(' ').toLowerCase();
            return haystack.contains(normalized);
          }).toList();

    filtered.sort((a, b) {
      return switch (sort) {
        LibrarySort.title => a.titleOrFallback.compareTo(b.titleOrFallback),
        LibrarySort.artist => a.artistOrFallback.compareTo(b.artistOrFallback),
        LibrarySort.album => a.albumOrFallback.compareTo(b.albumOrFallback),
        LibrarySort.duration => b.durationMs.compareTo(a.durationMs),
      };
    });
    return filtered;
  }

  @override
  Future<List<Track>> scanLibrary({bool force = false}) async {
    if (_cache.isNotEmpty && !force) {
      return _cache;
    }

    final permission = await ensurePermission();
    if (permission != PermissionAccess.granted) {
      _cache = const [];
      return _cache;
    }

    try {
      final songs = await _audioQuery.querySongs();
      _cache = songs.map(_mapSong).where((track) => track.path.isNotEmpty).toList();
      return _cache;
    } catch (error, stackTrace) {
      _logger.error('Failed to scan library', error, stackTrace);
      rethrow;
    }
  }

  Track _mapSong(SongModel song) {
    return Track(
      id: song.id,
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      path: song.data,
      durationMs: song.duration ?? 0,
      dateAdded: song.dateAdded == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(song.dateAdded!),
      albumId: song.albumId,
      artistId: song.artistId,
    );
  }
}

