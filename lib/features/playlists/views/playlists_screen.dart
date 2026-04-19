import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../viewmodels/playlists_viewmodel.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistsViewModelProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Playlists', style: Theme.of(context).textTheme.headlineMedium),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.playlists.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Create playlists for gym, focus, sleep, or commute sessions.'),
            ),
          )
        else
          ...state.playlists.map((playlist) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => _openPlaylistTracks(context, ref, playlist),
                title: Text(playlist.name),
                subtitle: Text('${playlist.trackIds.length} tracks'),
                leading: const Icon(Icons.queue_music_rounded),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'rename') {
                      _showRenameDialog(context, ref, playlist.id, playlist.name);
                    } else {
                      await ref
                          .read(playlistsViewModelProvider.notifier)
                          .deletePlaylist(playlist.id);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ];
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Late night coding'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(playlistsViewModelProvider.notifier)
                    .createPlaylist(controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename playlist'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(playlistsViewModelProvider.notifier)
                    .renamePlaylist(id, controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPlaylistTracks(
    BuildContext rootContext,
    WidgetRef ref,
    AppPlaylist playlist,
  ) async {
    final repository = ref.read(mediaLibraryRepositoryProvider);
    await repository.scanLibrary();
    final tracks = <Track>[];
    for (final trackId in playlist.trackIds) {
      final track = await repository.findTrackById(trackId);
      if (track != null) {
        tracks.add(track);
      }
    }

    if (!rootContext.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: rootContext,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            ListTile(
              title: Text(playlist.name),
              subtitle: Text('${tracks.length} tracks'),
              trailing: FilledButton.tonal(
                onPressed: tracks.isEmpty
                    ? null
                    : () async {
                        await ref
                            .read(homeViewModelProvider.notifier)
                            .playTrack(tracks.first, tracks);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        if (rootContext.mounted) {
                          rootContext.push('/player');
                        }
                      },
                child: const Text('Play'),
              ),
            ),
            const Divider(),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No playable tracks in this playlist.'),
              )
            else
              ...tracks.map((track) {
                return TrackTile(
                  track: track,
                  onTap: () async {
                    await ref
                        .read(homeViewModelProvider.notifier)
                        .playTrack(track, tracks);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    if (rootContext.mounted) {
                      rootContext.push('/player');
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: () async {
                      await ref
                          .read(playlistsViewModelProvider.notifier)
                          .removeTrack(playlist.id, track.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

