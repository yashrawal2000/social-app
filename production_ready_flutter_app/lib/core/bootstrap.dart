
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_logger.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.e('FlutterError', details.exception, details.stack ?? StackTrace.current);
  };

  await runZonedGuarded(() async {
    runApp(builder());
  }, (error, stack) {
    AppLogger.e('ZoneError', error, stack);
    // TODO: Forward to Crashlytics or Sentry if enabled.
  });
}
