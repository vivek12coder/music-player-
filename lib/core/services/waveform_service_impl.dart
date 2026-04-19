import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../contracts/app_contracts.dart';
import '../logging/app_logger.dart';
import '../models/app_models.dart';
import 'local_storage_service.dart';

class WaveformServiceImpl implements WaveformService {
  WaveformServiceImpl(this._storageService, this._logger);

  final LocalStorageService _storageService;
  final AppLogger _logger;

  Box<dynamic> get _box => _storageService.box(AppConstants.waveformBox);

  @override
  Future<List<double>> loadWaveform(Track track) async {
    try {
      final cachedPath = _box.get(track.id.toString()) as String?;
      if (cachedPath != null) {
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          final waveform = await JustWaveform.parse(cachedFile);
          return _normalizeWaveform(waveform);
        }
      }

      final directory = await getTemporaryDirectory();
      final outputFile = File('${directory.path}/${track.id}.wave');
      await for (final progress in JustWaveform.extract(
        audioInFile: File(track.path),
        waveOutFile: outputFile,
        zoom: const WaveformZoom.pixelsPerSecond(40),
      )) {
        if (progress.waveform != null) {
          await _box.put(track.id.toString(), outputFile.path);
          return _normalizeWaveform(progress.waveform!);
        }
      }
    } catch (error, stackTrace) {
      _logger.warning('Waveform extraction failed for track ${track.id}: $error');
      _logger.error('Waveform stack', error, stackTrace);
    }

    return List<double>.generate(48, (index) {
      final cycle = index.isEven ? 0.75 : 0.35;
      return cycle;
    });
  }

  List<double> _normalizeWaveform(Waveform waveform) {
    if (waveform.length == 0) {
      return const [];
    }
    return List<double>.generate(waveform.length, (index) {
      final max = waveform.getPixelMax(index).abs().toDouble();
      final min = waveform.getPixelMin(index).abs().toDouble();
      final peak = max > min ? max : min;
      return (peak / 32768).clamp(0.08, 1.0);
    });
  }
}

