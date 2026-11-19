import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../game_state.dart';
import '../theme.dart';
import '../widgets/hex_button.dart';
import '../widgets/player_panel.dart';
import '../widgets/radial_menu.dart';
import 'dice_sheet.dart';
import 'players_screen.dart';
import 'settings_sheet.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game});

  final GameState game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _menuOpen = false;

  GameState get game => widget.game;

  @override
  void initState() {
    super.initState();
    _syncWakelock();
  }

  void _syncWakelock() {
    WakelockPlus.toggle(enable: game.keepAwake);
  }

  void _closeMenu() => setState(() => _menuOpen = false);

  void _onHexTap() {
    if (game.highRollValues != null) {
      game.closeHighRoll();
    } else {
      setState(() => _menuOpen = !_menuOpen);
    }
  }

  Future<void> _showSheet(Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(child: child),
    );
  }

  List<RadialMenuItem> get _menuItems => [
        RadialMenuItem('RESTART', const Color(0xFFFFE070), () {
          _closeMenu();
          game.restart();
        }),
        RadialMenuItem('HIGH ROLL', const Color(0xFF1FC8FF), () {
          _closeMenu();
          game.startHighRoll();
        }),
        RadialMenuItem('DICE', const Color(0xFFFF9F1C), () {
          _closeMenu();
          _showSheet(const DiceSheet());
        }),
        RadialMenuItem('SETTINGS', const Color(0xFFA99BFF), () async {
          _closeMenu();
          await _showSheet(SettingsSheet(game: game));
          _syncWakelock();
        }),
        RadialMenuItem('HELP', const Color(0xFFFF2D6F), () {
          _closeMenu();
          _showHelp();
        }),
        RadialMenuItem('PLAYERS', const Color(0xFF1EE07F), () {
          _closeMenu();
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PlayersScreen(game: game),
          ));
        }),
      ];

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: sheetColor,
        title: Text('HOW TO USE', style: labelStyle(32, color: Colors.white)),
        content: const Text(
          '• Tap the right side of a panel for +1, the left side for −1.\n'
          '• Hold for +10 / −10 (keeps going while you hold).\n'
          '• The small number above a total shows the recent change.\n'
          '• Center button → menu: restart, choose players & layout, '
          'high roll to see who goes first, roll dice, settings.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('GOT IT', style: labelStyle(22, color: accentGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) => Stack(
            children: [
              Positioned.fill(child: _grid()),
              if (_menuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: const ColoredBox(color: Colors.black54),
                  ),
                ),
              if (_menuOpen)
                Positioned.fill(child: RadialMenu(items: _menuItems)),
              Center(
                child: HexButton(
                  open: _menuOpen || game.highRollValues != null,
                  onTap: _onHexTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    final rows = game.layout.rows;
    final rolls = game.highRollValues;
    final winner = game.highRollWinner;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < rows[r].length; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _panel(
                          game.layout.indexOf(r, c),
                          rows[r][c],
                          rolls,
                          winner,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel(int index, int turns, List<int>? rolls, int? winner) {
    return PlayerPanel(
      player: game.players[index],
      quarterTurns: turns,
      onChange: (amount) => game.changeLife(index, amount),
      highRoll: rolls?[index],
      highRollFaded: winner != null && winner != index,
    );
  }
}
