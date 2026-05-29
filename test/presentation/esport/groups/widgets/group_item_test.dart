import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/presentation/esport/groups/widgets/group_item.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  GNEsportGroup group({required String description, int members = 2}) {
    return GNEsportGroup(
      id: 'g-1',
      groupName: 'Nhóm PES',
      ownerId: 'u-1',
      members: List.generate(members, (index) => 'u-$index'),
      description: description,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );
  }

  testWidgets('GroupItem hiển thị description khi không rỗng', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        GroupItem(
          group: group(description: 'Nhóm cầu thủ nòng cốt'),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Nhóm PES'), findsOneWidget);
    expect(find.text('Nhóm cầu thủ nòng cốt'), findsOneWidget);
    expect(find.text('2 thành viên'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    final description = tester.widget<Text>(find.text('Nhóm cầu thủ nòng cốt'));
    expect(
      description.style?.color,
      equals(
        Theme.of(
          tester.element(find.byType(GroupItem)),
        ).colorScheme.onSurfaceVariant,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
