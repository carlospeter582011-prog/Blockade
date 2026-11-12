import 'dart:math' as math;

import 'package:flutter/material.dart' hide Orientation;

import 'board.dart';

const _ink = Color(0xff121b20);
const _panel = Color(0xff1c2b32);
const _muted = Color(0xffadc0c3);
const _teal = Color(0xff76e6c4);
const _amber = Color(0xffffbf73);
const _invalid = Color(0xffff797d);

Color _color(Side side) => side == Side.teal ? _teal : _amber;

void main() => runApp(const BlockadeApp());

class BlockadeApp extends StatelessWidget {
  const BlockadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Board _game = Board();
  Side _starter = Side.teal;
  final _boardKey = GlobalKey();
  Orientation? _wallMode;
  Wall? _preview;
  WallError? _error;

  void _resetSelection() {
    _wallMode = null;
    _preview = null;
    _error = null;
  }

  void _newGame() {
    setState(() {
      _starter = _starter.other;
      _game = Board(turn: _starter);
      _resetSelection();
    });
  }

  Future<void> _restart() async {
    if (_game.winner != null) {
      _newGame();
      return;
    }
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text('The current match will end.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New match'),
          ),
        ],
      ),
    );
    if (mounted && restart == true) _newGame();
  }

  void _showRules() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play'),
        content: const SingleChildScrollView(
          child: Text(
            'Take turns on the same phone. Reach any square on the far edge first.\n\n'
            'Move one square up, down, left or right, or place one of your ten walls. '
            'Tap a highlighted square to move. Jump over an adjacent pawn if the '
            'space behind it is open. Otherwise, jump to an open side beside it.\n\n'
            'To build a wall, choose an orientation and tap the board, or drag the '
            'wall onto the board. Confirm the preview to end your turn. Walls '
            'span two squares and cannot cross, overlap or close off every route.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Wall _wallAt(Offset local, double step, Orientation orientation) => (
    x: (local.dx / step - 1).round().clamp(0, Board.size - 2),
    y: (local.dy / step - 1).round().clamp(0, Board.size - 2),
    orientation: orientation,
  );

  void _previewWall(Wall wall) {
    if (_preview == wall) return;
    setState(() {
      _wallMode = wall.orientation;
      _preview = wall;
      _error = _game.checkWall(wall);
    });
  }

  void _previewDrag(DragTargetDetails<Orientation> details) {
    final board = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (board == null) return;
    _previewWall(
      _wallAt(
        board.globalToLocal(details.offset),
        board.size.width / Board.size,
        details.data,
      ),
    );
  }

  void _move(Cell destination) {
    if (_game.move(destination)) setState(_resetSelection);
  }

  void _confirmWall() {
    final wall = _preview;
    if (wall != null && _game.placeWall(wall)) setState(_resetSelection);
  }

  void _selectWall(Orientation orientation) {
    setState(() {
      final next = _wallMode == orientation ? null : orientation;
      _resetSelection();
      _wallMode = next;
    });
  }

  Widget _header() => Row(
    children: [
      const Icon(Icons.grid_on_rounded, color: _teal, size: 22),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Blockade',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        onPressed: _restart,
        tooltip: 'New match',
        icon: const Icon(Icons.restart_alt_rounded),
      ),
      IconButton(
        onPressed: _showRules,
        tooltip: 'How to play',
        icon: const Icon(Icons.help_outline_rounded),
      ),
    ],
  );

  Widget _player(Side side) {
    final active = _game.turn == side && _game.winner == null;
    final color = _color(side);
    final remaining = _game.remaining(side);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: active ? color : Colors.transparent),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              side.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          Semantics(
            label: '${side.label}, $remaining walls left',
            excludeSemantics: true,
            child: Text(
              '$remaining walls',
              style: const TextStyle(color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _board(double size) {
    final step = size / Board.size;
    final moves = _wallMode == null ? _game.legalMoves() : <Cell>{};
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff273a42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DragTarget<Orientation>(
        key: _boardKey,
        onWillAcceptWithDetails: (_) =>
            _game.winner == null && _game.remaining(_game.turn) > 0,
        onMove: _previewDrag,
        onAcceptWithDetails: _previewDrag,
        onLeave: (_) => setState(_resetSelection),
        builder: (context, candidates, rejected) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (event) {
            final mode = _wallMode;
            if (mode != null) {
              _previewWall(_wallAt(event.localPosition, step, mode));
            }
          },
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoardPainter(
                      game: _game,
                      moves: moves,
                      preview: _preview,
                      invalid: _error != null,
                    ),
                  ),
                ),
                for (final move in moves)
                  Positioned(
                    left: step * move.x,
                    top: step * move.y,
                    width: step,
                    height: step,
                    child: Semantics(
                      label:
                          'Move to ${String.fromCharCode(65 + move.x)}${move.y + 1}',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _move(move),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wallChoice(Orientation orientation) {
    final horizontal = orientation == Orientation.horizontal;
    final icon = horizontal
        ? Icons.horizontal_rule_rounded
        : Icons.more_vert_rounded;
    final label = horizontal ? 'Horizontal' : 'Vertical';
    final available = _game.remaining(_game.turn) > 0;
    final selected = _wallMode == orientation;
    final color = _color(_game.turn);
    return Draggable<Orientation>(
      data: orientation,
      maxSimultaneousDrags: available ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(12, 12),
        child: Icon(icon, color: color, size: 36),
      ),
      child: OutlinedButton.icon(
        onPressed: available ? () => _selectWall(orientation) : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? color : Colors.white,
          side: BorderSide(color: selected ? color : _muted.withAlpha(110)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        ),
        icon: horizontal
            ? const Icon(Icons.horizontal_rule_rounded, size: 17)
            : const RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.horizontal_rule_rounded, size: 17),
              ),
        label: Text(label),
      ),
    );
  }

  Widget _controls() {
    final winner = _game.winner;
    final title = winner == null
        ? '${_game.turn.label} to move'
        : '${winner.label} wins';
    final hint = switch (_error) {
      WallError.occupied => 'Walls can’t cross or overlap.',
      WallError.blockedPath => 'Both players need a path to the far edge.',
      WallError.empty => 'You’re out of walls.',
      WallError.outside => 'Place the wall between board squares.',
      WallError.finished => 'This match has ended.',
      null when winner != null => 'Reached the far edge.',
      null when _preview != null => 'Tap another spot or confirm the wall.',
      null when _wallMode != null => 'Tap the board to preview the wall.',
      null when _game.remaining(_game.turn) == 0 => 'Tap a highlighted square.',
      null => 'Tap a highlighted square or choose a wall.',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            title,
            style: TextStyle(
              color: _color(winner ?? _game.turn),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(hint, style: TextStyle(color: _error == null ? _muted : _invalid)),
        const SizedBox(height: 7),
        if (winner != null)
          FilledButton(onPressed: _newGame, child: const Text('Play again'))
        else
          Wrap(
            spacing: 7,
            runSpacing: 3,
            children: [
              if (_preview == null) ...[
                _wallChoice(Orientation.horizontal),
                _wallChoice(Orientation.vertical),
              ],
              if (_wallMode != null)
                TextButton(
                  onPressed: () => setState(_resetSelection),
                  child: const Text('Cancel'),
                ),
              if (_preview != null)
                FilledButton(
                  onPressed: _error == null ? _confirmWall : null,
                  child: const Text('Place wall'),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 600 &&
                constraints.maxWidth > constraints.maxHeight;
            if (wide) {
              final size = math.min(
                500.0,
                math.min(
                  constraints.maxHeight - 24,
                  constraints.maxWidth * .56,
                ),
              );
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _board(size),
                      const SizedBox(width: 16),
                      Flexible(
                        child: SizedBox(
                          width: 315,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(),
                                const SizedBox(height: 6),
                                _player(Side.amber),
                                const SizedBox(height: 6),
                                _player(Side.teal),
                                const SizedBox(height: 12),
                                _controls(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final width = math.min(500.0, constraints.maxWidth - 24);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 7),
                      _player(Side.amber),
                      const SizedBox(height: 7),
                      _board(width),
                      const SizedBox(height: 7),
                      _player(Side.teal),
                      const SizedBox(height: 10),
                      _controls(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.game,
    required this.moves,
    required this.preview,
    required this.invalid,
  });

  final Board game;
  final Set<Cell> moves;
  final Wall? preview;
  final bool invalid;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / Board.size;
    final gap = step * .075;
    final paint = Paint();

    Offset center(Cell cell) =>
        Offset((cell.x + .5) * step, (cell.y + .5) * step);

    for (var y = 0; y < Board.size; y++) {
      paint.color = switch (y) {
        0 => const Color(0xff386352),
        Board.size - 1 => const Color(0xff72553e),
        _ => const Color(0xff344a53),
      };
      for (var x = 0; x < Board.size; x++) {
        final square = Rect.fromLTWH(
          x * step,
          y * step,
          step,
          step,
        ).deflate(gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(square, Radius.circular(gap * 1.6)),
          paint,
        );
      }
    }

    paint.color = _color(game.turn).withAlpha(195);
    for (final move in moves) {
      canvas.drawCircle(center(move), step * .10, paint);
    }

    for (final side in Side.values) {
      final position = center(game.pawn(side));
      paint.color = _ink.withAlpha(160);
      canvas.drawCircle(position.translate(0, step * .055), step * .315, paint);
      paint.color = _color(side);
      canvas.drawCircle(position, step * .29, paint);
      paint.color = Colors.white.withAlpha(145);
      canvas.drawCircle(
        position.translate(-step * .075, -step * .075),
        step * .065,
        paint,
      );
    }

    void drawWall(Wall wall, Color color, bool ghost) {
      final midpoint = Offset((wall.x + 1) * step, (wall.y + 1) * step);
      final horizontal = wall.orientation == Orientation.horizontal;
      final span = step * .91;
      final axis = horizontal ? Offset(span, 0) : Offset(0, span);
      paint
        ..strokeCap = StrokeCap.round
        ..strokeWidth = step * (ghost ? .19 : .14)
        ..color = color;
      canvas.drawLine(midpoint - axis, midpoint + axis, paint);
    }

    for (final entry in game.walls) {
      drawWall(entry.key, _color(entry.value), false);
    }
    if (preview case final Wall wall) {
      drawWall(wall, invalid ? _invalid : Colors.white.withAlpha(230), true);
    }
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}
