import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/repositories/user_library_repository_impl.dart';
import '../../features/library/repositories/media_library_repository_impl.dart';
import '../../features/playlists/repositories/playlist_repository_impl.dart';
import '../../features/recommendations/services/smart_shuffle_service.dart';
import '../contracts/app_contracts.dart';
import '../logging/app_logger.dart';
import '../services/equalizer_service_impl.dart';
import '../services/local_storage_service.dart';
import '../services/music_audio_handler.dart';
import '../services/permission_service_impl.dart';
import '../services/waveform_service_impl.dart';

final loggerProvider = Provider<AppLogger>((ref) => AppLogger());

final storageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Storage service is injected during bootstrap.');
});

final audioHandlerProvider = Provider<MusicAudioHandler>((ref) {
  throw UnimplementedError('Audio handler is injected during bootstrap.');
});

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  throw UnimplementedError('Audio playback service is injected during bootstrap.');
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

final equalizerServiceProvider = Provider<EqualizerService>((ref) {
  return EqualizerServiceImpl();
});

final waveformServiceProvider = Provider<WaveformService>((ref) {
  return WaveformServiceImpl(
    ref.watch(storageServiceProvider),
    ref.watch(loggerProvider),
  );
});

final mediaLibraryRepositoryProvider = Provider<MediaLibraryRepository>((ref) {
  return MediaLibraryRepositoryImpl(
    ref.watch(permissionServiceProvider),
    ref.watch(loggerProvider),
  );
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(ref.watch(storageServiceProvider));
});

final userLibraryRepositoryProvider = Provider<UserLibraryRepository>((ref) {
  return UserLibraryRepositoryImpl(ref.watch(storageServiceProvider));
});

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return const SmartShuffleService();
});
