
import 'dart:developer' as dev;

class AppLogger {
  static void d(String message, {String name = 'APP'}) {
    dev.log(message, name: name);
  }

  static void e(String message, Object error, StackTrace stack, {String name = 'APP'}) {
    dev.log(message, name: name, error: error, stackTrace: stack);
  }
}
