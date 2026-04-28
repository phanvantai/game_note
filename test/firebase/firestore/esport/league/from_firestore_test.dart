import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock implements DocumentSnapshot<Object?> {}

void main() {
  test('GNEsportLeague.fromFirestore wrap đúng fromMap', () {
    final doc = _MockDoc();
    when(() => doc.id).thenReturn('Lx');
    when(() => doc.data()).thenReturn(<String, dynamic>{
      GNEsportLeague.fieldOwnerId: 'owner',
      GNEsportLeague.fieldGroupId: 'G1',
      GNEsportLeague.fieldName: 'Wrap',
      GNEsportLeague.fieldStartDate: Timestamp.fromDate(DateTime(2026, 1, 1)),
      GNEsportLeague.fieldIsActive: true,
      GNEsportLeague.fieldDescription: 'd',
      GNEsportLeague.fieldParticipants: <String>[],
    });

    final restored = GNEsportLeague.fromFirestore(doc);
    expect(restored.id, 'Lx');
    expect(restored.name, 'Wrap');
    expect(restored.startDate, DateTime(2026, 1, 1));
  });

  test('GNEsportMatch.fromFirestore wrap đúng fromMap', () {
    final doc = _MockDoc();
    when(() => doc.id).thenReturn('Mx');
    when(() => doc.data()).thenReturn(<String, dynamic>{
      GNEsportMatch.fieldHomeTeamId: 'A',
      GNEsportMatch.fieldAwayTeamId: 'B',
      GNEsportMatch.fieldHomeScore: 2,
      GNEsportMatch.fieldAwayScore: 1,
      GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 5)),
      GNEsportMatch.fieldIsFinished: true,
      GNEsportMatch.fieldLeagueId: 'L1',
      GNEsportMatch.fieldMatchCost: 50000,
    });

    final restored = GNEsportMatch.fromFirestore(doc);
    expect(restored.id, 'Mx');
    expect(restored.matchCost, 50000);
    expect(restored.date, DateTime(2026, 5, 5));
  });
}
