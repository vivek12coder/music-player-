import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(bootstrap.storageService),
        loggerProvider.overrideWithValue(bootstrap.logger),
        audioPlaybackServiceProvider.overrideWithValue(bootstrap.audioHandler),
        audioHandlerProvider.overrideWithValue(bootstrap.audioHandler),
      ],
      child: const PulsePlayApp(),
    ),
  );
}

