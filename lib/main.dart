import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Root interceptor to mark all Alt combinations as handled
  HardwareKeyboard.instance.addHandler(_suppressAltSounds);

  runApp(
    const ProviderScope(
      child: DhandasApp(),
    ),
  );
}

bool _suppressAltSounds(KeyEvent event) {
  if (HardwareKeyboard.instance.isAltPressed) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      return true;
    }
  }
  return false;
}