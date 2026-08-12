import 'package:flutter_test/flutter_test.dart';

import 'package:pes_arena/routing.dart';

void main() {
  group('Routing constants', () {
    test('exposes stable route constants', () {
      expect(Routing.app, '/');
      expect(Routing.splash, '/splash');
      expect(Routing.language, '/language');
      expect(Routing.login, '/login');
      expect(Routing.completeProfile, '/complete-profile');
      expect(Routing.groups, '/groups');
      expect(Routing.league, '/league');
      expect(Routing.createTeam, '/create-team');
      expect(Routing.groupDetail, '/group');
      expect(Routing.tournamentDetail, '/tournament');
      expect(Routing.updateProfile, '/update-profile');
      expect(Routing.setting, '/setting');
      expect(Routing.changePassword, '/change-password');
      expect(Routing.dashboardDetail, '/dashboard');
      expect(Routing.feedback, '/feedback');
    });
  });

  group('Routing detail path helpers', () {
    test('builds group and tournament routes from IDs', () {
      expect(Routing.groupDetailPath('group-1'), '/group/group-1');
      expect(Routing.groupDetailPath(''), '/group/');
      expect(
        Routing.tournamentDetailPath('tournament-1'),
        '/tournament/tournament-1',
      );
      expect(Routing.tournamentDetailPath(''), '/tournament/');
    });
  });

  group('Routing.safeNextLocation', () {
    test('handles empty, null, and malformed input', () {
      expect(Routing.safeNextLocation(null), '/');
      expect(Routing.safeNextLocation(''), '/');
      expect(Routing.safeNextLocation('not-a-url%'), '/');
      expect(Routing.safeNextLocation('https://example.com/group/abc'), '/');
      expect(Routing.safeNextLocation('mailto:user@example.com'), '/');
      expect(Routing.safeNextLocation('myapp://foo/bar'), '/');
    });

    test('allows public and fixed protected paths', () {
      for (final path in <String>[
        Routing.language,
        Routing.login,
        Routing.splash,
        Routing.completeProfile,
        Routing.app,
        Routing.groups,
        Routing.updateProfile,
        Routing.setting,
        Routing.changePassword,
        Routing.dashboardDetail,
        Routing.feedback,
      ]) {
        expect(Routing.safeNextLocation(path), path);
      }
    });

    test('preserves query and fragment on valid dynamic routes', () {
      expect(
        Routing.safeNextLocation('/group/group-1?foo=bar&deep=1'),
        '/group/group-1?foo=bar&deep=1',
      );
      expect(
        Routing.safeNextLocation('/tournament/tournament-1?round=final'),
        '/tournament/tournament-1?round=final',
      );
      expect(
        Routing.safeNextLocation('/group/group-1#section'),
        '/group/group-1#section',
      );
    });

    test('rejects unknown or malformed routes', () {
      expect(Routing.safeNextLocation('/group'), '/');
      expect(Routing.safeNextLocation('/tournament'), '/');
      expect(Routing.safeNextLocation('/group/'), '/');
      expect(Routing.safeNextLocation('/tournament/'), '/');
      expect(Routing.safeNextLocation('/group/abc/extra'), '/');
      expect(Routing.safeNextLocation('/legacy-route'), '/');
      expect(Routing.safeNextLocation('/create-team'), '/');
      expect(Routing.safeNextLocation('/legacy-route#unknown'), '/');
      expect(Routing.safeNextLocation('/offline'), Routing.app);
      expect(Routing.safeNextLocation('/offline/league'), Routing.app);
      expect(Routing.safeNextLocation('/sync-offline-data'), Routing.app);
      expect(Routing.safeNextLocation('/notification'), Routing.app);
    });
  });
}
