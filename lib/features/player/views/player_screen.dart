import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/widgets/app_widgets.dart';
import '../viewmodels/player_viewmodel.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerViewModelProvider);
    final snapshot = state.snapshot;
    final track = snapshot.currentTrack;

    if (track == null) {
      return const Scaffold(
        body: Center(child: Text('Select a song from your library to start playing.')),
      );
    }

    final progress = snapshot.duration.inMilliseconds == 0
        ? 0.0
        : snapshot.position.inMilliseconds / snapshot.duration.inMilliseconds;

    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            onPressed: () => ref.read(playerViewModelProvider.notifier).toggleFavorite(),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'artwork-${track.id}',
                child: ArtworkCard(trackId: track.id, size: 320),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < 0) {
                  ref.read(playerViewModelProvider.notifier).next();
                } else if ((details.primaryVelocity ?? 0) > 0) {
                  ref.read(playerViewModelProvider.notifier).previous();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.titleOrFallback, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(track.artistOrFallback, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 18),
                  WaveformVisualizer(data: state.waveform, progress: progress.clamp(0, 1)),
                  Slider(
                    value: snapshot.position.inMilliseconds.toDouble().clamp(
                          0,
                          snapshot.duration.inMilliseconds.toDouble() == 0
                              ? 1
                              : snapshot.duration.inMilliseconds.toDouble(),
                        ),
                    max: snapshot.duration.inMilliseconds.toDouble() == 0
                        ? 1
                        : snapshot.duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      ref
                          .read(playerViewModelProvider.notifier)
                          .seek(Duration(milliseconds: value.round()));
                    },
                  ),
                  Row(
                    children: [
                      Text(_format(snapshot.position)),
                      const Spacer(),
                      Text(_format(snapshot.duration)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => ref.read(playerViewModelProvider.notifier).toggleShuffle(),
                  icon: Icon(
                    snapshot.shuffleEnabled ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(playerViewModelProvider.notifier).previous(),
                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                ),
                FilledButton(
                  onPressed: () => ref.read(playerViewModelProvider.notifier).togglePlayPause(),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(22),
                  ),
                  child: Icon(
                    snapshot.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 34,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(playerViewModelProvider.notifier).next(),
                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                ),
                IconButton(
                  onPressed: () => _showPlaybackTools(context, ref, state),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Playback controls'),
                    const SizedBox(height: 12),
                    _InlineSlider(
                      label: 'Volume',
                      value: snapshot.volume,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        ref.read(playerViewModelProvider.notifier).setVolume(value);
                      },
                    ),
                    _InlineSlider(
                      label: 'Speed',
                      value: snapshot.speed,
                      min: 0.75,
                      max: 1.5,
                      onChanged: (value) {
                        ref.read(playerViewModelProvider.notifier).setSpeed(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _showPlaybackTools(
    BuildContext context,
    WidgetRef ref,
    PlayerState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF131720),
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const SectionHeader(title: 'Sleep timer'),
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60].map((minutes) {
                return ActionChip(
                  label: Text('$minutes min'),
                  onPressed: () {
                    ref
                        .read(playerViewModelProvider.notifier)
                        .startSleepTimer(Duration(minutes: minutes));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            if (state.snapshot.sleepTimerState.isActive) ...[
              const SizedBox(height: 10),
              ActionChip(
                label: const Text('Stop timer'),
                onPressed: () {
                  ref.read(playerViewModelProvider.notifier).stopSleepTimer();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: 18),
            const SectionHeader(title: 'Repeat mode'),
            Wrap(
              spacing: 8,
              children: RepeatModeSetting.values.map((mode) {
                return ChoiceChip(
                  label: Text(mode.name),
                  selected: state.snapshot.repeatMode == mode,
                  onSelected: (_) {
                    ref.read(playerViewModelProvider.notifier).setRepeatMode(mode);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            if (state.equalizerSupported) ...[
              const SectionHeader(title: 'Equalizer'),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
                value: state.equalizerEnabled,
                onChanged: (enabled) {
                  ref
                      .read(playerViewModelProvider.notifier)
                      .setEqualizerEnabled(enabled);
                },
              ),
              const SizedBox(height: 10),
              ...List.generate(state.bandLevels.length, (index) {
                final frequency = state.bandFrequencies.length > index
                    ? state.bandFrequencies[index]
                    : (index + 1) * 1000;
                return _InlineSlider(
                  label: '${frequency ~/ 1000} kHz',
                  value: state.bandLevels[index].toDouble(),
                  min: state.bandRange.first.toDouble(),
                  max: state.bandRange.last.toDouble(),
                  onChanged: (value) {
                    ref
                        .read(playerViewModelProvider.notifier)
                        .updateBand(index, value.round());
                  },
                );
              }),
              Wrap(
                spacing: 8,
                children: List.generate(state.presets.length, (index) {
                  final label = state.presets[index];
                  return ActionChip(
                    label: Text(label),
                    onPressed: () {
                      ref.read(playerViewModelProvider.notifier).usePreset(index);
                    },
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InlineSlider extends StatelessWidget {
  const _InlineSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

