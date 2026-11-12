import 'package:blockade/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('local game fits ${size.width}×${size.height}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const BlockadeApp());

      expect(tester.takeException(), isNull);
      expect(find.text('Teal to move'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Move to E8'));
      await tester.pumpAndSettle();
      expect(find.text('Amber to move'), findsOneWidget);

      await tester.tap(find.text('Horizontal'));
      await tester.pumpAndSettle();
      final board = find.byWidgetPredicate((widget) => widget is DragTarget);
      await tester.tapAt(tester.getCenter(board));
      await tester.pumpAndSettle();
      final place = find.text('Place wall');
      await tester.ensureVisible(place);
      await tester.tap(place);
      await tester.pumpAndSettle();
      expect(find.text('Teal to move'), findsOneWidget);
      expect(find.text('9 walls'), findsOneWidget);
    });
  }

  testWidgets('drag a wall and confirm its position', (tester) async {
    await tester.pumpWidget(const BlockadeApp());
    final start = tester.getCenter(find.text('Vertical'));
    final board = find.byWidgetPredicate((widget) => widget is DragTarget);
    await tester.dragFrom(start, tester.getCenter(board) - start);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place wall'));
    await tester.pumpAndSettle();
    expect(find.text('Amber to move'), findsOneWidget);
    expect(find.text('9 walls'), findsOneWidget);
  });
}
