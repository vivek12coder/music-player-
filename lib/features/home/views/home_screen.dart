import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(homeViewModelProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
        children: [
          Text('MUSIC PLAYER', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Developed by OpenGeek Community',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Local music, smooth playback, and smart shuffle tuned for your daily listening.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFF3DE0C2)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Shuffle',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Build a behavior-driven queue from your favorites, skips, and time-of-day habits.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(homeViewModelProvider.notifier).playSmartShuffle();
                    if (context.mounted) {
                      context.push('/player');
                    }
                  },
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.82),
                  ),
                  child: const Text('Start Smart Shuffle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Recently played',
            action: TextButton(
              onPressed: () => context.go('/library'),
              child: const Text('View library'),
            ),
          ),
          const SizedBox(height: 12),
          if (state.recentlyPlayed.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Your recently played songs will appear here.'),
              ),
            )
          else
            ...state.recentlyPlayed.take(6).map((track) {
              return TrackTile(
                track: track,
                onTap: () async {
                  await ref
                      .read(homeViewModelProvider.notifier)
                      .playTrack(track, state.recentlyPlayed);
                  if (context.mounted) {
                    context.push('/player');
                  }
                },
              );
            }),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recommended for you'),
          const SizedBox(height: 12),
          ...state.recommendations.map((section) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(section.subtitle),
                    const SizedBox(height: 12),
                    ...section.tracks.take(4).map((track) {
                      final isFavorite = state.favoriteIds.contains(track.id);
                      return TrackTile(
                        track: track,
                        onTap: () async {
                          await ref
                              .read(homeViewModelProvider.notifier)
                              .playTrack(track, section.tracks);
                          if (context.mounted) {
                            context.push('/player');
                          }
                        },
                        trailing: IconButton(
                          onPressed: () async {
                            await ref
                                .read(homeViewModelProvider.notifier)
                                .toggleFavorite(track.id);
                          },
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
