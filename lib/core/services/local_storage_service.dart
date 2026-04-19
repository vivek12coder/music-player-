import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

class LocalStorageService {
  LocalStorageService(this._logger);

  final AppLogger _logger;

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.playlistsBox),
      Hive.openBox<dynamic>(AppConstants.favoritesBox),
      Hive.openBox<dynamic>(AppConstants.recentlyPlayedBox),
      Hive.openBox<dynamic>(AppConstants.playStatsBox),
      Hive.openBox<dynamic>(AppConstants.settingsBox),
      Hive.openBox<dynamic>(AppConstants.sleepTimerBox),
      Hive.openBox<dynamic>(AppConstants.equalizerBox),
      Hive.openBox<dynamic>(AppConstants.waveformBox),
    ]);
    _logger.info('Hive boxes opened');
  }

  Box<dynamic> box(String name) => Hive.box<dynamic>(name);
}
