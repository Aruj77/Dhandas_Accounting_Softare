import 'dart:async';
import 'package:flutter/foundation.dart';

class LoadingStatus {
  final bool isLoading;
  final String message;

  const LoadingStatus({
    this.isLoading = false,
    this.message = 'Processing...',
  });
}

class LoadingService {
  static final ValueNotifier<LoadingStatus> statusNotifier =
      ValueNotifier<LoadingStatus>(const LoadingStatus());

  static Timer? _debounceTimer;

  /// Displays the global frosted-glass loader with an optional status label.
  /// Uses a micro-debounce of 80ms to avoid flashing for instantaneous tasks.
  static void show([String message = 'Processing...']) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 80), () {
      statusNotifier.value = LoadingStatus(isLoading: true, message: message);
    });
  }

  /// Dismisses the active loader.
  static void hide() {
    _debounceTimer?.cancel();
    if (statusNotifier.value.isLoading) {
      statusNotifier.value = const LoadingStatus(isLoading: false);
    }
  }

  /// Wraps any asynchronous computation, ensuring the loader starts and stops safely.
  static Future<T> wrap<T>(
    Future<T> Function() computation, {
    String message = 'Processing...',
  }) async {
    show(message);
    try {
      return await computation();
    } finally {
      hide();
    }
  }
}