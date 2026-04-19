import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../home/viewmodels/home_viewmodel.dart';

class SettingsState {
  const SettingsState({
    this.permission = PermissionAccess.unknown,
    this.sleepTimerState = const SleepTimerState(isActive: false),
    this.equalizerPreset,
    this.isLoading = false,
  });

  final PermissionAccess permission;
  final SleepTimerState sleepTimerState;
  final EqualizerPreset? equalizerPreset;
  final bool isLoading;

  SettingsState copyWith({
    PermissionAccess? permission,
    SleepTimerState? sleepTimerState,
    EqualizerPreset? equalizerPreset,
    bool? isLoading,
  }) {
    return SettingsState(
      permission: permission ?? this.permission,
      sleepTimerState: sleepTimerState ?? this.sleepTimerState,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel(this._ref) : super(const SettingsState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> clearHistory() async {
    await _ref.read(userLibraryRepositoryProvider).clearHistory();
    _ref.invalidate(homeViewModelProvider);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final permission = await _ref.read(permissionServiceProvider).checkLibraryPermission();
    final sleep = await _ref.read(userLibraryRepositoryProvider).getSleepTimer();
    final equalizer = await _ref.read(userLibraryRepositoryProvider).getEqualizerPreset();
    state = state.copyWith(
      permission: permission,
      sleepTimerState: sleep,
      equalizerPreset: equalizer,
      isLoading: false,
    );
  }

  Future<void> openSettings() =>
      _ref.read(permissionServiceProvider).openSettings();
}

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel(ref);
});
