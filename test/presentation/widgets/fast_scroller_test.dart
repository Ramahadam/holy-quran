import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/widgets/fast_scroller.dart';

Widget _list(
  ScrollController controller, {
  int count = 200,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: Scaffold(
    body: Directionality(
      textDirection: direction,
      child: FastScroller(
        controller: controller,
        labelBuilder: () {
          if (!controller.hasClients) return null;
          return 'Row ${(controller.offset / 50).floor()}';
        },
        child: ListView.builder(
          controller: controller,
          itemExtent: 50,
          itemCount: count,
          itemBuilder: (context, index) => Text('Row $index'),
        ),
      ),
    ),
  ),
);

void main() {
  const handle = ValueKey('fastScrollHandle');
  const bubble = ValueKey('fastScrollLabel');

  testWidgets('handle stays hidden until the list scrolls', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_list(controller));
    expect(find.byKey(handle).hitTestable(), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.byKey(handle).hitTestable(), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(handle).hitTestable(), findsNothing);
  });

  testWidgets('dragging the handle jumps and labels the position', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_list(controller));
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(handle)),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(find.byKey(bubble), findsOneWidget);

    await gesture.moveTo(Offset(tester.getCenter(find.byKey(handle)).dx, 2000));
    await tester.pump();
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(
      find.descendant(
        of: find.byKey(bubble),
        matching: find.text(
          'Row ${(controller.position.maxScrollExtent / 50).floor()}',
        ),
      ),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pump();
    expect(find.byKey(bubble), findsNothing);
  });

  testWidgets('short content gets no handle', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_list(controller, count: 20));
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(find.byKey(handle), findsNothing);
  });

  testWidgets('handle sits on the start edge in RTL', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_list(controller, direction: TextDirection.rtl));
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(tester.getCenter(find.byKey(handle)).dx, lessThan(100));
  });
}
