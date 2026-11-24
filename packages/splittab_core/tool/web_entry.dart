// Entry point for the "does it still work with JavaScript numbers?" check.
// Compiled with `dart compile js` and driven by tool/web_check.js (Node).
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:splittab_core/splittab_core.dart';

void main() {
  globalContext['computeCaseJson'] = ((JSString input) {
    final json = jsonDecode(input.toDart) as Map<String, Object?>;
    final out = computeCaseJson(
        json, (i) => computeTrip(i.trip, i.expenses, i.payments));
    return jsonEncode(out).toJS;
  }).toJS;
}
