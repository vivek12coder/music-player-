import 'dart:io';

import 'package:flutter/services.dart';

import '../contracts/app_contracts.dart';

class EqualizerServiceImpl implements EqualizerService {
  static const MethodChannel _channel = MethodChannel('pulseplay/equalizer');

  @override
  Future<List<int>> getBandFrequencies() async {
    final values = await _channel.invokeListMethod<dynamic>('getBandFrequencies');
    return values?.cast<int>() ?? [];
  }

  @override
  Future<List<int>> getBandLevelRange() async {
    final values = await _channel.invokeListMethod<dynamic>('getBandLevelRange');
    return values?.cast<int>() ?? const [-1500, 1500];
  }

  @override
  Future<List<int>> getBandLevels() async {
    final values = await _channel.invokeListMethod<dynamic>('getBandLevels');
    return values?.cast<int>() ?? [];
  }

  @override
  Future<List<String>> getPresets() async {
    final values = await _channel.invokeListMethod<dynamic>('getPresets');
    return values?.cast<String>() ?? [];
  }

  @override
  Future<void> init(int sessionId) {
    return _channel.invokeMethod<void>('init', {'sessionId': sessionId});
  }

  @override
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return (await _channel.invokeMethod<bool>('isSupported')) ?? false;
  }

  @override
  Future<void> release() => _channel.invokeMethod<void>('release');

  @override
  Future<void> setBandLevel(int band, int level) {
    return _channel.invokeMethod<void>(
      'setBandLevel',
      {'band': band, 'level': level},
    );
  }

  @override
  Future<void> setEnabled(bool enabled) {
    return _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }

  @override
  Future<void> usePreset(int presetIndex) {
    return _channel.invokeMethod<void>('usePreset', {'preset': presetIndex});
  }
}

