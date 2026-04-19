import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/core/providers/app_providers.dart';
import 'package:music_player/features/playlists/viewmodels/playlists_viewmodel.dart';

import '../support/fakes.dart';

void main() {
  test('PlaylistsViewModel creates playlists', () async {
    final container = ProviderContainer(
      overrides: [
        playlistRepositoryProvider.overrideWithValue(FakePlaylistRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(playlistsViewModelProvider.notifier);
    await notifier.createPlaylist('Roadtrip');

    final state = container.read(playlistsViewModelProvider);
    expect(state.playlists, isNotEmpty);
    expect(state.playlists.first.name, 'Roadtrip');
  });
}

