typedef Cell = ({int x, int y});
typedef Wall = ({int x, int y, Orientation orientation});

enum Orientation { horizontal, vertical }

enum Side {
  teal(8, 0),
  amber(0, 8);

  const Side(this.home, this.goal);

  final int home;
  final int goal;

  Side get other => this == teal ? amber : teal;
  String get label => this == teal ? 'Teal' : 'Amber';
}

enum WallError { outside, occupied, blockedPath, empty, finished }

class Board {
  Board({this.turn = Side.teal});

  static const size = 9;
  static const stock = 10;
  static const _steps = [
    (x: 0, y: -1),
    (x: 1, y: 0),
    (x: 0, y: 1),
    (x: -1, y: 0),
  ];

  Side turn;
  Side? winner;
  final _pawns = {for (final side in Side.values) side: (x: 4, y: side.home)};
  final _remaining = {for (final side in Side.values) side: stock};
  final Map<Wall, Side> _walls = {};

  Cell pawn(Side side) => _pawns[side]!;
  int remaining(Side side) => _remaining[side]!;
  Iterable<MapEntry<Wall, Side>> get walls => _walls.entries;

  static bool _onBoard(Cell cell) =>
      cell.x >= 0 && cell.y >= 0 && cell.x < size && cell.y < size;

  static Cell _add(Cell a, Cell b) => (x: a.x + b.x, y: a.y + b.y);

  bool _hasWall(int x, int y, Orientation orientation, Wall? candidate) {
    final wall = (x: x, y: y, orientation: orientation);
    return wall == candidate || _walls.containsKey(wall);
  }

  bool _open(Cell from, Cell to, [Wall? candidate]) {
    if (!_onBoard(to)) return false;
    if (from.x == to.x) {
      final y = from.y < to.y ? from.y : to.y;
      return !_hasWall(from.x, y, Orientation.horizontal, candidate) &&
          !_hasWall(from.x - 1, y, Orientation.horizontal, candidate);
    }
    final x = from.x < to.x ? from.x : to.x;
    return !_hasWall(x, from.y, Orientation.vertical, candidate) &&
        !_hasWall(x, from.y - 1, Orientation.vertical, candidate);
  }

  Set<Cell> legalMoves() {
    if (winner != null) return {};
    final start = pawn(turn);
    final opponent = pawn(turn.other);
    final result = <Cell>{};
    for (final step in _steps) {
      final next = _add(start, step);
      if (!_open(start, next)) continue;
      if (next != opponent) {
        result.add(next);
        continue;
      }

      final jump = _add(next, step);
      if (_open(next, jump)) {
        result.add(jump);
        continue;
      }
      final perpendicular = (x: step.y, y: step.x);
      final sides = [perpendicular, (x: -perpendicular.x, y: -perpendicular.y)];
      for (final side in sides) {
        final diagonal = _add(next, side);
        if (_open(next, diagonal)) result.add(diagonal);
      }
    }
    return result;
  }

  bool move(Cell destination) {
    if (!legalMoves().contains(destination)) return false;
    _pawns[turn] = destination;
    if (destination.y == turn.goal) {
      winner = turn;
    } else {
      turn = turn.other;
    }
    return true;
  }

  WallError? checkWall(Wall wall) {
    if (winner != null) return WallError.finished;
    if (remaining(turn) == 0) return WallError.empty;
    final (x: x, y: y, orientation: orientation) = wall;
    if (x < 0 || y < 0 || x >= size - 1 || y >= size - 1) {
      return WallError.outside;
    }
    final horizontal = orientation == Orientation.horizontal;
    final across = horizontal ? Orientation.vertical : Orientation.horizontal;
    final dx = horizontal ? 1 : 0;
    final dy = horizontal ? 0 : 1;
    if (_hasWall(x, y, orientation, null) ||
        _hasWall(x, y, across, null) ||
        _hasWall(x - dx, y - dy, orientation, null) ||
        _hasWall(x + dx, y + dy, orientation, null)) {
      return WallError.occupied;
    }
    if (Side.values.any((side) => !_hasRoute(side, wall))) {
      return WallError.blockedPath;
    }
    return null;
  }

  bool _hasRoute(Side side, Wall candidate) {
    final pending = [pawn(side)];
    final visited = {pending.first};
    for (var i = 0; i < pending.length; i++) {
      final cell = pending[i];
      if (cell.y == side.goal) return true;
      for (final step in _steps) {
        final next = _add(cell, step);
        if (_open(cell, next, candidate) && visited.add(next)) {
          pending.add(next);
        }
      }
    }
    return false;
  }

  bool placeWall(Wall wall) {
    if (checkWall(wall) != null) return false;
    _walls[wall] = turn;
    _remaining[turn] = remaining(turn) - 1;
    turn = turn.other;
    return true;
  }
}
