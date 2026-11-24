import 'package:material_ui/material_ui.dart';

import 'data/store.dart';
import 'design/theme.dart';
import 'design/tokens.dart';
import 'screens/trips_screen.dart';

void main() {
  runApp(const SplitTabApp());
}

class SplitTabApp extends StatefulWidget {
  const SplitTabApp({super.key, this.state});

  /// Lets tests provide their own state.
  final AppState? state;

  @override
  State<SplitTabApp> createState() => _SplitTabAppState();
}

class _SplitTabAppState extends State<SplitTabApp> {
  late final AppState _state = widget.state ?? AppState();

  @override
  void initState() {
    super.initState();
    if (_state.loading) _state.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'SplitTab',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(AppPalette.light),
        darkTheme: buildTheme(AppPalette.dark),
        themeMode: ThemeMode.system,
        builder: (context, child) => ColoredBox(
          color: context.palette.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: child,
            ),
          ),
        ),
        home: const TripsScreen(),
      ),
    );
  }
}
