import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_state.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const LifeCounterApp());
}

class LifeCounterApp extends StatefulWidget {
  const LifeCounterApp({super.key});

  @override
  State<LifeCounterApp> createState() => _LifeCounterAppState();
}

class _LifeCounterAppState extends State<LifeCounterApp> {
  final _game = GameState();

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4452FF),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: GameScreen(game: _game),
    );
  }
}
