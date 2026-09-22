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


// import 'package:flutter/material.dart';
// import 'app.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const DhandasApp());
// }



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Consume every Alt+<key> at the hardware level so Windows never sees an
  // "unhandled menu accelerator" and plays its system beep (this is what
  // caused the beep on Alt+E / Alt+Q / Alt+A / etc across the app).
  HardwareKeyboard.instance.addHandler(_suppressAltSounds);

  runApp(const DhandasApp());
}

bool _suppressAltSounds(KeyEvent event) {
  if (HardwareKeyboard.instance.isAltPressed) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // Returning true tells the engine this hardware event is consumed,
      // so it never falls through to the OS's default Alt-accelerator beep.
      return true;
    }
  }
  return false;
}
