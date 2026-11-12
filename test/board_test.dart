import 'package:blockade/board.dart';
import 'package:flutter_test/flutter_test.dart';

Wall horizontal(int x, int y) =>
    (x: x, y: y, orientation: Orientation.horizontal);
Wall vertical(int x, int y) => (x: x, y: y, orientation: Orientation.vertical);

void move(Board board, int x, int y) {
  expect(board.move((x: x, y: y)), isTrue);
}

Board adjacentPawns() {
  final board = Board();
  for (var turn = 1; turn <= 3; turn++) {
    move(board, 4, 8 - turn);
    move(board, 4, turn);
  }
  move(board, 3, 5);
  move(board, 4, 4);
  move(board, 4, 5);
  return board;
}

void main() {
  test('a turn allows one valid action and switches players', () {
    final board = Board();
    expect(board.legalMoves(), {(x: 3, y: 8), (x: 4, y: 7), (x: 5, y: 8)});
    expect(board.move((x: 5, y: 7)), isFalse);
    expect(board.turn, Side.teal);
    move(board, 4, 7);
    expect(board.turn, Side.amber);
    expect(board.placeWall(horizontal(3, 6)), isTrue);
    expect(board.remaining(Side.amber), 9);
    expect(board.legalMoves(), isNot(contains((x: 4, y: 6))));
  });

  test('the opponent can be jumped straight when the landing is open', () {
    final board = adjacentPawns();
    expect(board.turn, Side.amber);
    expect(board.legalMoves(), contains((x: 4, y: 6)));
    expect(board.legalMoves(), isNot(contains((x: 3, y: 5))));
    expect(board.legalMoves(), isNot(contains((x: 4, y: 5))));
  });

  test('a wall behind the opponent allows jumps around its sides', () {
    final blocked = adjacentPawns();
    expect(blocked.placeWall(horizontal(4, 3)), isTrue);
    expect(blocked.legalMoves(), containsAll([(x: 3, y: 4), (x: 5, y: 4)]));
    expect(blocked.legalMoves(), isNot(contains((x: 4, y: 3))));
  });

  test('walls reject crossing, overlap and an out-of-board position', () {
    final board = Board();
    expect(board.placeWall(horizontal(3, 3)), isTrue);
    expect(board.checkWall(vertical(3, 3)), WallError.occupied);
    expect(board.checkWall(horizontal(4, 3)), WallError.occupied);
    expect(board.checkWall(horizontal(8, 3)), WallError.outside);
    expect(board.checkWall(horizontal(5, 3)), isNull);
    expect(board.turn, Side.amber);
    expect(board.remaining(Side.amber), 10);
  });

  test('walls cannot seal the final path to a goal', () {
    final board = Board();
    expect(board.placeWall(vertical(2, 7)), isTrue);
    expect(board.placeWall(vertical(4, 7)), isTrue);
    expect(board.checkWall(horizontal(3, 7)), WallError.blockedPath);
    expect(board.placeWall(horizontal(3, 7)), isFalse);
    expect(board.remaining(Side.teal), 9);
    expect(board.turn, Side.teal);
  });

  test('any square on the far edge wins and ends the match', () {
    final board = Board();
    move(board, 3, 8);
    move(board, 5, 0);
    for (var y = 7; y >= 0; y--) {
      move(board, 3, y);
      if (y > 0) move(board, y.isOdd ? 6 : 5, 0);
    }
    expect(board.winner, Side.teal);
    expect(board.legalMoves(), isEmpty);
    expect(board.checkWall(horizontal(0, 0)), WallError.finished);
  });

  test('a player who runs out of walls can still move', () {
    final board = Board();
    for (var i = 0; i < 10; i++) {
      expect(
        board.placeWall(horizontal((i % 4) * 2, (i ~/ 4) * 2 + 1)),
        isTrue,
      );
      move(board, i.isEven ? 3 : 4, 0);
    }
    expect(board.remaining(Side.teal), 0);
    expect(board.checkWall(vertical(0, 0)), WallError.empty);
    move(board, 4, 7);
  });
}
