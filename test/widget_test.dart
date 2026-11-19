import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/game_state.dart';
import 'package:life_counter/layouts.dart';

void main() {
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
}
