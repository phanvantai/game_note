import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation code does not contain hard-coded user-facing UI strings', () {
    final libDir = Directory('lib');
    final dartFiles =
        libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.contains('/l10n/generated/'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final patterns = <RegExp>[
      RegExp("\\bText\\s*\\(\\s*const\\s*['\"]"),
      RegExp("\\bText\\s*\\(\\s*['\"]"),
      RegExp("\\bTab\\s*\\(\\s*text\\s*:\\s*['\"]"),
      RegExp("\\btitle\\s*:\\s*['\"]"),
      RegExp("\\bsubtitle\\s*:\\s*['\"]"),
      RegExp("\\btooltip\\s*:\\s*['\"]"),
      RegExp("\\bhintText\\s*:\\s*['\"]"),
      RegExp("\\blabelText\\s*:\\s*['\"]"),
      RegExp("\\bhelperText\\s*:\\s*['\"]"),
      RegExp("\\bshowToast\\s*\\(\\s*['\"]"),
      RegExp("\\bSnackBar\\s*\\(\\s*content\\s*:\\s*Text\\s*\\(\\s*['\"]"),
    ];

    final allowed = <String>{
      // App identity and developer-only fallback paths are intentionally fixed.
      'lib/firebase_options.dart',
    };

    final failures = <String>[];
    for (final file in dartFiles) {
      if (allowed.contains(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('context.l10n') || line.contains('.l10n')) continue;
        if (line.contains("Text('\${") || line.contains('Text("\${')) {
          continue;
        }
        if (line.contains("subtitle: '\${") ||
            line.contains('subtitle: "\${')) {
          continue;
        }
        if (line.contains("Text('#')")) continue;
        if (patterns.any((pattern) => pattern.hasMatch(line))) {
          failures.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Move these user-facing UI strings to AppLocalizations:\n'
          '${failures.take(200).join('\n')}'
          '${failures.length > 200 ? '\n...and ${failures.length - 200} more' : ''}',
    );
  });
}
