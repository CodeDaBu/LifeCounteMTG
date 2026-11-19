/// A table layout: a list of rows, each row a list of panels.
/// Each number is the panel's quarter turns (0 = upright, 1 = faces the
/// left edge, 2 = upside down, 3 = faces the right edge).
class GameLayout {
  const GameLayout(this.rows);

  final List<List<int>> rows;

  int get playerCount => rows.fold(0, (sum, row) => sum + row.length);

  /// Player index of the panel at [row], [col] (reading order).
  int indexOf(int row, int col) {
    var i = 0;
    for (var r = 0; r < row; r++) {
      i += rows[r].length;
    }
    return i + col;
  }
}

const Map<int, List<GameLayout>> layoutsByCount = {
  1: [
    GameLayout([
      [0],
    ]),
  ],
  2: [
    GameLayout([
      [2],
      [0],
    ]),
    GameLayout([
      [1, 3],
    ]),
  ],
  3: [
    GameLayout([
      [2],
      [1, 3],
    ]),
    GameLayout([
      [1, 3],
      [0],
    ]),
  ],
  4: [
    GameLayout([
      [1, 3],
      [1, 3],
    ]),
    GameLayout([
      [2],
      [1, 3],
      [0],
    ]),
  ],
  5: [
    GameLayout([
      [1, 3],
      [1, 3],
      [0],
    ]),
    GameLayout([
      [2],
      [1, 3],
      [1, 3],
    ]),
  ],
  6: [
    GameLayout([
      [1, 3],
      [1, 3],
      [1, 3],
    ]),
    GameLayout([
      [2],
      [1, 3],
      [1, 3],
      [0],
    ]),
  ],
};

final GameLayout defaultLayout = layoutsByCount[4]!.first;
