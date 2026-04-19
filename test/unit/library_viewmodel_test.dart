import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/core/providers/app_providers.dart';
import 'package:music_player/features/library/viewmodels/library_viewmodel.dart';

import '../support/fakes.dart';

void main() {
  test('LibraryViewModel loads and filters tracks', () async {
    final container = ProviderContainer(
      overrides: [
        mediaLibraryRepositoryProvider.overrideWithValue(FakeMediaLibraryRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(libraryViewModelProvider.notifier);
    await notifier.loadLibrary();
    expect(container.read(libraryViewModelProvider).tracks.length, 2);

    await notifier.search('soft');
    expect(container.read(libraryViewModelProvider).tracks.single.title, 'Soft Focus');
  });
}

