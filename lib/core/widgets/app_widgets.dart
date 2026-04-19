import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../features/player/viewmodels/player_viewmodel.dart';
import '../models/app_models.dart';

class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final playerState = ref.watch(playerViewModelProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF161922),
              Color(0xFF090B0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: child),
              if (playerState.snapshot.currentTrack != null)
                MiniPlayer(snapshot: playerState.snapshot),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        index: _resolveIndex(path),
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/library');
          } else if (index == 2) {
            context.go('/playlists');
          } else {
            context.go('/settings');
          }
        },
      ),
    );
  }

  int _resolveIndex(String path) {
    if (path.startsWith('/library')) {
      return 1;
    }
    if (path.startsWith('/playlists')) {
      return 2;
    }
    if (path.startsWith('/settings')) {
      return 3;
    }
    return 0;
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.index,
    required this.onTap,
    super.key,
  });

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
        NavigationDestination(icon: Icon(Icons.queue_music_outlined), label: 'Playlists'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }
}

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({
    required this.trackId,
    this.size = 56,
    super.key,
  });

  final int trackId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: QueryArtworkWidget(
        id: trackId,
        type: ArtworkType.AUDIO,
        artworkHeight: size,
        artworkWidth: size,
        nullArtworkWidget: Container(
          width: size,
          height: size,
          color: const Color(0xFF1B2030),
          child: const Icon(Icons.graphic_eq_rounded),
        ),
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({required this.snapshot, super.key});

  final PlaybackSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = snapshot.currentTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => context.push('/player'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121722),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            ArtworkCard(trackId: track.id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.titleOrFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    track.artistOrFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(playerViewModelProvider.notifier).previous();
              },
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton.filledTonal(
              onPressed: () {
                ref.read(playerViewModelProvider.notifier).togglePlayPause();
              },
              icon: Icon(
                snapshot.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(playerViewModelProvider.notifier).next();
              },
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.action,
    super.key,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class TrackTile extends ConsumerWidget {
  const TrackTile({
    required this.track,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: ArtworkCard(trackId: track.id),
      title: Text(
        track.titleOrFallback,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${track.artistOrFallback} • ${_formatDuration(track.duration)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class PermissionGate extends StatelessWidget {
  const PermissionGate({
    required this.onPressed,
    this.title = 'Give MUSIC PLAYER access to your audio library.',
    this.actionLabel = 'Grant Access',
    super.key,
  });

  final VoidCallback onPressed;
  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({
    required this.data,
    required this.progress,
    super.key,
  });

  final List<double> data;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length.clamp(0, 60), (index) {
          final active = index / (data.isEmpty ? 1 : data.length) <= progress;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 12 + (data[index] * 60),
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
