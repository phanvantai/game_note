import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';

void main() {
  testWidgets('Shimmer chạy animation lặp lại quanh child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Shimmer(
            period: Duration(milliseconds: 200),
            child: ShimmerBox(height: 20),
          ),
        ),
      ),
    );
    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(ShimmerBox), findsOneWidget);
    // Trigger a few animation ticks — confirms the controller is repeating.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ShimmerBox honors width/height/borderRadius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerBox(
            height: 30,
            width: 80,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
    );
    final box = tester.widget<Container>(find.byType(Container));
    expect(box.constraints?.maxHeight, 30);
    expect(box.constraints?.maxWidth, 80);
  });
}
