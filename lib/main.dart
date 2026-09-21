// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'app.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Root interceptor to mark all Alt combinations as handled
//   // HardwareKeyboard.instance.addHandler(_suppressAltSounds);

//   runApp(const DhandasApp());
// }

// // bool _suppressAltSounds(KeyEvent event) {
// //   if (HardwareKeyboard.instance.isAltPressed) {
// //     if (event is KeyDownEvent || event is KeyRepeatEvent) {
// //       // Returning true instructs Flutter that this hardware event is consumed
// //       return true;
// //     }
// //   }
// //   return false;
// // }


import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DhandasApp());
}