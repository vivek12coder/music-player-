import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../../playlists/viewmodels/playlists_viewmodel.dart';
import '../viewmodels/library_viewmodel.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (!_scrollController.hasClients) {
          return;
        }
        final threshold = _scrollController.position.maxScrollExtent - 320;
        if (_scrollController.position.pixels >= threshold) {
          ref.read(libraryViewModelProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryViewModelProvider);

    if (state.permission != PermissionAccess.granted &&
        !state.isLoading &&
        state.tracks.isEmpty) {
      final permanentlyDenied = state.permission == PermissionAccess.permanentlyDenied;
      return PermissionGate(
        title: permanentlyDenied
            ? 'Storage access is blocked for this app.'
            : 'Give PulsePlay access to your audio library.',
        actionLabel: permanentlyDenied ? 'Open Settings' : 'Grant Access',
        onPressed: permanentlyDenied
            ? () => ref.read(permissionServiceProvider).openSettings()
            : () => ref.read(libraryViewModelProvider.notifier).loadLibrary(force: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(libraryViewModelProvider.notifier).loadLibrary(force: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
        itemCount: state.tracks.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Library', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                SearchBar(
                  hintText: 'Search songs, artists, albums',
                  onChanged: ref.read(libraryViewModelProvider.notifier).search,
                  trailing: [
                    PopupMenuButton<LibrarySort>(
                      icon: const Icon(Icons.sort_rounded),
                      onSelected: ref.read(libraryViewModelProvider.notifier).updateSort,
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(value: LibrarySort.title, child: Text('Title')),
                          PopupMenuItem(value: LibrarySort.artist, child: Text('Artist')),
                          PopupMenuItem(value: LibrarySort.album, child: Text('Album')),
                          PopupMenuItem(value: LibrarySort.duration, child: Text('Duration')),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        _Stat(label: 'Songs', value: '${state.totalTracks}'),
                        _Stat(label: 'Albums', value: '${state.albums.length}'),
                        _Stat(label: 'Artists', value: '${state.artists.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          if (index == state.tracks.length + 1) {
            if (state.tracks.isEmpty && !state.isLoading) {
              return const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Center(child: Text('No audio files matched your search.')),
              );
            }
            return const SizedBox(height: 12);
          }

          if (index == state.tracks.length + 2) {
            if (!state.hasMore) {
              return const SizedBox.shrink();
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            );
          }

          final track = state.tracks[index - 1];
          return TrackTile(
            track: track,
            onTap: () async {
              final notifier = ref.read(homeViewModelProvider.notifier);
              await notifier.playTrack(track, state.allTracks);
              if (context.mounted) {
                context.push('/player');
              }
            },
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'add_to_playlist') {
                  await _showAddToPlaylistSheet(track.id);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Text('Add to playlist'),
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddToPlaylistSheet(int trackId) async {
    final playlists = await ref.read(playlistRepositoryProvider).getPlaylists();
    if (!mounted) {
      return;
    }

    if (playlists.isEmpty) {
      final controller = TextEditingController();
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Create a playlist first'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Weekend vibes'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  final playlist = await ref
                      .read(playlistRepositoryProvider)
                      .createPlaylist(name);
                  await ref
                      .read(playlistsViewModelProvider.notifier)
                      .addTrack(playlist.id, trackId);
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Added to ${playlist.name}')),
                  );
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          children: playlists.map((playlist) {
            return ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(playlist.name),
              subtitle: Text('${playlist.trackIds.length} tracks'),
              onTap: () async {
                final navigator = Navigator.of(context);
                await ref
                    .read(playlistsViewModelProvider.notifier)
                    .addTrack(playlist.id, trackId);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Added to ${playlist.name}')),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
