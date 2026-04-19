import 'package:audio_service/audio_service.dart';

import '../core/logging/app_logger.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/music_audio_handler.dart';

class AppBootstrap {
  AppBootstrap({
    required this.storageService,
    required this.audioHandler,
    required this.logger,
  });

  final LocalStorageService storageService;
  final MusicAudioHandler audioHandler;
  final AppLogger logger;

  static Future<AppBootstrap> initialize() async {
    final logger = AppLogger();
    final storageService = LocalStorageService(logger);
    await storageService.initialize();

    MusicAudioHandler audioHandler;
    try {
      audioHandler = await AudioService.init(
        builder: () => MusicAudioHandler(
          storageService: storageService,
          logger: logger,
        ),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.example.music_player.playback',
          androidNotificationChannelName: 'MUSIC PLAYER Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      logger.warning('AudioService init failed. Starting in fallback mode.');
      logger.error('AudioService init error', error, stackTrace);
      audioHandler = MusicAudioHandler(
        storageService: storageService,
        logger: logger,
      );
    }

    return AppBootstrap(
      storageService: storageService,
      audioHandler: audioHandler,
      logger: logger,
    );
  }
}

