import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fixgo/app/fixgo_app.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          Sentry.captureException(details.exception, stackTrace: details.stack);
        }
      };

      runZonedGuarded(() {
        runApp(const FixGoApp());
      }, (error, stack) {
        Sentry.captureException(error, stackTrace: stack);
      });
    },
  );
}
