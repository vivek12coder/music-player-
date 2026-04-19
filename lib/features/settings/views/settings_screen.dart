import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_clock_outlined),
                title: const Text('Sleep timer'),
                subtitle: Text(
                  state.sleepTimerState.isActive
                      ? 'Ends in ${state.sleepTimerState.remaining.inMinutes} minutes'
                      : 'Currently disabled',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Equalizer preset'),
                subtitle: Text(state.equalizerPreset?.name ?? 'Not configured yet'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.perm_media_outlined),
                title: const Text('Media permission'),
                subtitle: Text(state.permission.name),
                trailing: TextButton(
                  onPressed: () => ref.read(settingsViewModelProvider.notifier).openSettings(),
                  child: const Text('Open settings'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Clear play history'),
                subtitle: const Text('Resets recently played and smart-shuffle stats'),
                onTap: () => ref.read(settingsViewModelProvider.notifier).clearHistory(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'MUSIC PLAYER is developed by OpenGeek Community with Riverpod, MVVM, just_audio, audio_service, Hive CE, and on-device recommendations.',
            ),
          ),
        ),
      ],
    );
  }
}

