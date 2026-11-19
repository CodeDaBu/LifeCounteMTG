import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/game_state.dart';
import 'package:life_counter/layouts.dart';
import 'package:life_counter/screens/game_screen.dart';
import 'package:life_counter/theme.dart';

void main() {
  setUpAll(() => useGoogleFonts = false);

  group('GameState', () {
    test('starts with 4 players at 40 life', () {
      final game = GameState();
      expect(game.players.length, 4);
      expect(game.players.every((p) => p.life == 40), isTrue);
      game.dispose();
    });

    test('changeLife updates life and recent delta', () {
      final game = GameState();
      game.changeLife(0, -1);
      game.changeLife(0, -10);
      expect(game.players[0].life, 29);
      expect(game.players[0].recentDelta, -11);
      expect(game.players[1].life, 40);
      game.dispose();
    });

    test('changing layout and starting life resets players', () {
      final game = GameState();
      game.changeLife(2, 5);
      game.setLayout(layoutsByCount[6]!.first);
      expect(game.players.length, 6);
      game.setStartingLife(20);
      expect(game.players.every((p) => p.life == 20), isTrue);
      game.dispose();
    });

    test('high roll gives distinct d20 values', () {
      final game = GameState();
      for (var i = 0; i < 100; i++) {
        final rolls = game.rollDistinct(6);
        expect(rolls.toSet().length, 6);
        expect(rolls.every((r) => r >= 1 && r <= 20), isTrue);
      }
      game.dispose();
    });

    test('ten poison knocks a player out; unkill brings them back', () {
      final game = GameState();
      game.addCounter(1, CounterType.poison);
      for (var i = 0; i < 9; i++) {
        game.changeCounter(1, CounterType.poison, 1);
      }
      expect(game.players[1].isOut, isFalse);
      game.changeCounter(1, CounterType.poison, 1);
      expect(game.players[1].isOut, isTrue);
      game.toggleKill(1); // unkill
      expect(game.players[1].isOut, isFalse);
      game.toggleKill(1); // kill again
      expect(game.players[1].isOut, isTrue);
      game.dispose();
    });

    test('counters never go below zero and empty ones can be hidden', () {
      final game = GameState();
      game.addCounter(0, CounterType.energy);
      game.changeCounter(0, CounterType.energy, -1);
      expect(game.players[0].counter(CounterType.energy), 0);
      game.removeEmptyCounters(0);
      expect(game.players[0].counters, isEmpty);
      game.dispose();
    });

    test('commander damage lowers life and 21 from one commander is lethal',
        () {
      final game = GameState();
      for (var i = 0; i < 20; i++) {
        game.changeCommanderDamage(0, 2, 0, 1);
      }
      expect(game.players[0].damageFrom(2, 0), 20);
      expect(game.players[0].life, 20);
      expect(game.players[0].isOut, isFalse);
      game.changeCommanderDamage(0, 2, 0, 1);
      expect(game.players[0].isOut, isTrue);
      game.changeCommanderDamage(0, 2, 0, -1);
      expect(game.players[0].life, 20);
      expect(game.players[0].isOut, isFalse);
      game.dispose();
    });

    test('commander damage can leave life alone', () {
      final game = GameState()..setCommanderDamageReducesLife(false);
      game.changeCommanderDamage(0, 1, 0, 5);
      expect(game.players[0].life, 40);
      expect(game.players[0].damageFrom(1, 0), 5);
      game.dispose();
    });

    test('partners track two commanders; removing partner drops the second',
        () {
      final game = GameState();
      game.togglePartner(3);
      game.changeCommanderDamage(0, 3, 0, 2);
      game.changeCommanderDamage(0, 3, 1, 4);
      expect(game.players[0].damageFrom(3, 1), 4);
      game.togglePartner(3);
      expect(game.players[0].damageFrom(3, 1), 0);
      expect(game.players[0].damageFrom(3, 0), 2);
      game.dispose();
    });

    test('monarch and initiative belong to one player at a time', () {
      final game = GameState();
      game.toggleMonarch(0);
      game.toggleMonarch(2);
      expect(game.monarch, 2);
      game.toggleMonarch(2);
      expect(game.monarch, isNull);
      game.toggleInitiative(1);
      expect(game.initiative, 1);
      game.dispose();
    });

    test('names and colors survive a restart', () {
      final game = GameState();
      game.setName(0, ' alice ');
      game.setColor(0, backgroundChoices.last);
      game.restart();
      expect(game.players[0].name, 'ALICE');
      expect(game.players[0].color, backgroundChoices.last);
      game.dispose();
    });

    test('layout index is reading order', () {
      const layout = GameLayout([
        [2],
        [1, 3],
        [0],
      ]);
      expect(layout.playerCount, 4);
      expect(layout.indexOf(1, 1), 2);
      expect(layout.indexOf(2, 0), 3);
    });
  });

  group('GameScreen', () {
    late GameState game;

    // Player 1's panel faces left, so the panel's top-left corner (just
    // the name, nothing tappable) is the screen's top-right corner.
    Future<void> tapOutsideEditor(WidgetTester tester) async {
      final barrier = find.byKey(const ValueKey('editor-barrier'));
      // getTopLeft gives the panel's own top-left, in screen coordinates.
      await tester.tapAt(tester.getTopLeft(barrier) + const Offset(-20, 20));
      await tester.pumpAndSettle();
    }

    Future<void> pumpGame(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      game = GameState();
      addTearDown(game.dispose);
      await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    }

    testWidgets('tapping halves changes life and history records it',
        (tester) async {
      await pumpGame(tester);
      expect(find.text('40'), findsNWidgets(4));

      await tester.tap(find.byKey(const ValueKey('plus')).first);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('minus')).at(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(game.players[0].life, 41);
      expect(game.players[1].life, 39);
      expect(find.text('41'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(game.history.length, 2);
    });

    testWidgets('drawer steppers add poison; chip popup edits it',
        (tester) async {
      await pumpGame(tester);

      await tester.tap(find.byKey(const ValueKey('drawer-handle')).first);
      await tester.pumpAndSettle();
      final plus = find.byKey(const ValueKey('step-poison-plus')).first;
      await tester.ensureVisible(plus);
      await tester.pumpAndSettle();
      await tester.tap(plus);
      await tester.tap(plus);
      await tester.pump();
      expect(game.players[0].counter(CounterType.poison), 2);
      expect(game.players[0].life, 40);

      await tester.tap(find.byKey(const ValueKey('drawer-close')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chip-poison')), findsOneWidget);

      // Tap the chip: small editor; its halves change poison, not life.
      await tester.tap(find.byKey(const ValueKey('chip-poison')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('counter-editor')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit-plus')));
      await tester.pumpAndSettle();
      expect(game.players[0].counter(CounterType.poison), 3);
      expect(game.players[0].life, 40);

      // Tap outside closes it.
      await tapOutsideEditor(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('counter-editor')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('grid counter left at zero disappears when editor closes',
        (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-handle')).first);
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const ValueKey('grid-energy')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('grid-energy')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('counter-editor')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip-energy')), findsOneWidget);
      await tapOutsideEditor(tester);
      await tester.pumpAndSettle();
      expect(game.players[0].counters, isEmpty);
      expect(find.byKey(const ValueKey('chip-energy')), findsNothing);
    });

    testWidgets('swipe up opens drawer, swipe down closes it', (tester) async {
      await pumpGame(tester);
      // Player 0 sits on the left and faces left (quarterTurns 1), so the
      // panel's "up" is toward the screen's right edge.
      final panel = find.byKey(const ValueKey('minus')).first;
      await tester.fling(panel, const Offset(300, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-KILL')).hitTestable(),
          findsOneWidget);

      await tester.fling(find.byKey(const ValueKey('drawer-KILL')).first,
          const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-KILL')).hitTestable(),
          findsNothing);
    });

    testWidgets('commander damage view hits the right player', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-handle')).first);
      await tester.pumpAndSettle();
      // The grid is at the far end of the drawer; scroll to it.
      await tester
          .ensureVisible(find.byKey(const ValueKey('grid-commander')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('grid-commander')).first);
      await tester.pumpAndSettle();
      expect(find.text('COMMANDER DAMAGE TAKEN'), findsOneWidget);
      final view = find
          .ancestor(
              of: find.text('COMMANDER DAMAGE TAKEN'),
              matching: find.byType(Column))
          .first;
      final label = find.descendant(of: view, matching: find.text('PLAYER 2'));
      expect(label, findsOneWidget);
      // Three opponents, no tile for yourself.
      expect(find.descendant(of: view, matching: find.text('PLAYER 1')),
          findsNothing);

      // Tile showing damage from player 2 (index 1).
      final tile = find.ancestor(of: label, matching: find.byType(Stack)).first;
      await tester.tap(find.descendant(
          of: tile, matching: find.byKey(const ValueKey('plus'))));
      await tester.pumpAndSettle();
      expect(game.players[0].damageFrom(1, 0), 1);
      expect(game.players[0].life, 39);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('menu opens with all buttons and high roll shows numbers',
        (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      for (final label in [
        'RESTART',
        'HIGH ROLL',
        'DICE',
        'SETTINGS',
        'HELP',
        'HISTORY',
        'PLAYERS',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text('HIGH ROLL'));
      await tester.pump(const Duration(seconds: 2));
      expect(game.highRollValues, isNotNull);
      expect(game.isRolling, isFalse);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(game.highRollValues, isNull);
    });
  });
}
