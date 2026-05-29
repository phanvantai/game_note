import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/theme/app_theme.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';

Widget _wrapWithMaterial({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('AppPageBackground đặt đúng màu nền scaffold', (tester) async {
    const key = Key('page-bg');
    const child = Text('page-content');
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: const AppPageBackground(key: key, child: child),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(AppPageBackground),
        matching: find.byType(ColoredBox),
      ),
    );

    expect(background.color, AppTheme.light.scaffoldBackgroundColor);
    expect(find.text('page-content'), findsOneWidget);
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets(
    'AppSectionSurface dùng theme surface/outline và khoảng cách truyền vào',
    (tester) async {
      const sectionKey = Key('section-surface');
      const customPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      const customMargin = EdgeInsets.only(top: 4, bottom: 8);

      await tester.pumpWidget(
        _wrapWithMaterial(
          theme: AppTheme.dark,
          child: const AppSectionSurface(
            key: sectionKey,
            padding: customPadding,
            margin: customMargin,
            child: Text('section-content'),
          ),
        ),
      );

      final surface = tester.widget<Container>(
        find.descendant(
          of: find.byKey(sectionKey),
          matching: find.byType(Container),
        ),
      );
      final decoration = surface.decoration as BoxDecoration;
      final border = decoration.border as Border;
      final scheme = AppTheme.dark.colorScheme;

      expect(surface.padding, customPadding);
      expect(surface.margin, customMargin);
      expect(decoration.color, scheme.surface);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(border.top.color, scheme.outline);
    },
  );

  testWidgets('AppIconMark render đúng kích thước, nền và icon', (
    tester,
  ) async {
    const iconKey = Key('icon-mark');
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: const AppIconMark(
          key: iconKey,
          icon: Icons.sports_esports,
          size: 40,
        ),
      ),
    );

    final wrapper = tester.widget<Container>(
      find.descendant(
        of: find.byKey(iconKey),
        matching: find.byType(Container),
      ),
    );
    final decoration = wrapper.decoration as BoxDecoration;
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byKey(iconKey), matching: find.byType(Icon)),
    );
    final scheme = AppTheme.light.colorScheme;

    final markSize = tester.getSize(
      find
          .descendant(of: find.byKey(iconKey), matching: find.byType(Container))
          .first,
    );
    expect(markSize.width, 40);
    expect(markSize.height, 40);
    expect(decoration.color, scheme.surfaceContainerHighest);
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect((decoration.border as Border).left.color, scheme.outline);
    expect(icon.icon, Icons.sports_esports);
    expect(icon.size, 20);
    expect(icon.color, scheme.onSurface);
  });

  testWidgets(
    'AppCard áp dụng margin mặc định, hoặc tùy chỉnh khi truyền vào',
    (tester) async {
      const defaultCardKey = Key('default-card');
      const customCardKey = Key('custom-card');

      await tester.pumpWidget(
        _wrapWithMaterial(
          theme: AppTheme.light,
          child: const AppCard(
            key: defaultCardKey,
            child: Text('default-card-content'),
          ),
        ),
      );

      final defaultCard = tester.widget<Container>(
        find.descendant(
          of: find.byKey(defaultCardKey),
          matching: find.byType(Container),
        ),
      );
      final defaultScheme = AppTheme.light.colorScheme;

      expect(defaultCard.margin, const EdgeInsets.symmetric(horizontal: 16));
      expect(defaultCard.decoration, isA<BoxDecoration>());
      expect(
        (defaultCard.decoration as BoxDecoration).color,
        defaultScheme.surface,
      );
      expect((defaultCard.decoration as BoxDecoration).border, isA<Border>());

      await tester.pumpWidget(
        _wrapWithMaterial(
          theme: AppTheme.light,
          child: const AppCard(
            key: customCardKey,
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.all(12),
            child: Text('custom-card-content'),
          ),
        ),
      );

      final customCard = tester.widget<Container>(
        find.descendant(
          of: find.byKey(customCardKey),
          matching: find.byType(Container),
        ),
      );
      expect(customCard.margin, const EdgeInsets.only(top: 10));

      expect(
        find.descendant(
          of: find.byKey(customCardKey),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Padding && widget.padding == const EdgeInsets.all(12),
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('AppEmptyState hiển thị icon, title và subtitle', (tester) async {
    const emptyKey = Key('empty-state');
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: const AppEmptyState(
          key: emptyKey,
          icon: Icons.inbox_outlined,
          title: 'Không có dữ liệu',
          subtitle: 'Vui lòng thử lại sau',
        ),
      ),
    );

    final scheme = AppTheme.light.colorScheme;
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byKey(emptyKey), matching: find.byType(Icon)),
    );
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byKey(emptyKey),
        matching: find.text('Không có dữ liệu'),
      ),
    );
    final subtitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(emptyKey),
        matching: find.text('Vui lòng thử lại sau'),
      ),
    );

    expect(icon.icon, Icons.inbox_outlined);
    expect(icon.size, 44);
    expect(icon.color, scheme.onSurface.withValues(alpha: 0.36));
    expect(title.style?.color, scheme.onSurface.withValues(alpha: 0.5));
    expect(subtitle.style?.color, scheme.onSurface.withValues(alpha: 0.4));
    expect(find.text('Không có dữ liệu'), findsOneWidget);
    expect(find.text('Vui lòng thử lại sau'), findsOneWidget);
  });

  testWidgets('AppEmptyState không render subtitle khi không truyền', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: const AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Chỉ có tiêu đề',
        ),
      ),
    );

    expect(find.text('Chỉ có tiêu đề'), findsOneWidget);
    expect(find.text('Không có dữ liệu'), findsNothing);
  });

  testWidgets('appInputDecoration trả về decoration theo theme đang dùng', (
    tester,
  ) async {
    InputDecoration? capturedDecoration;

    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: Builder(
          builder: (context) {
            capturedDecoration = appInputDecoration(
              context: context,
              hintText: 'Nhập gì đó',
              labelText: 'Nhãn',
              prefixIcon: Icons.search,
              suffixIcon: const Icon(Icons.clear, key: Key('suffix')),
              errorText: 'Lỗi',
            );
            return TextField(decoration: capturedDecoration);
          },
        ),
      ),
    );

    final decoration = capturedDecoration!;
    final scheme = AppTheme.light.colorScheme;
    final borderRadius = BorderRadius.circular(8);

    expect(decoration.hintText, 'Nhập gì đó');
    expect(decoration.labelText, 'Nhãn');
    expect(decoration.errorText, 'Lỗi');
    expect(
      decoration.hintStyle?.color,
      scheme.onSurface.withValues(alpha: 0.4),
    );
    expect(
      (decoration.prefixIcon as Icon).color,
      scheme.onSurface.withValues(alpha: 0.56),
    );
    expect((decoration.suffixIcon as Icon).key, const Key('suffix'));
    expect(decoration.filled, true);
    expect(decoration.fillColor, scheme.surfaceContainerHighest);
    expect(
      decoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    expect(
      (decoration.border as OutlineInputBorder).borderSide.color,
      scheme.outline,
    );
    expect(
      (decoration.border as OutlineInputBorder).borderRadius,
      borderRadius,
    );
    expect(
      (decoration.enabledBorder as OutlineInputBorder).borderSide.color,
      scheme.outline,
    );
    expect(
      (decoration.focusedBorder as OutlineInputBorder).borderSide,
      BorderSide(width: 1.5, color: scheme.primary),
    );
    expect(
      (decoration.errorBorder as OutlineInputBorder).borderSide.color,
      scheme.error,
    );
  });

  testWidgets('showAppConfirmDialog trả về false/true đúng theo action', (
    tester,
  ) async {
    Future<bool?>? futureResult;

    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                futureResult = showAppConfirmDialog(
                  context: context,
                  title: 'Xác nhận xóa',
                  message: 'Bạn có muốn tiếp tục không?',
                  isDestructive: true,
                );
              },
              child: const Text('Mở confirm'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Mở confirm'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Xác nhận xóa'), findsOneWidget);
    expect(find.text('Bạn có muốn tiếp tục không?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirm'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(await futureResult, isFalse);

    await tester.tap(find.text('Mở confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(await futureResult, isTrue);
  });

  testWidgets('showAppConfirmDialog dùng text tuỳ chỉnh', (tester) async {
    Future<bool?>? futureResult;
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                futureResult = showAppConfirmDialog(
                  context: context,
                  title: 'Đồng ý',
                  message: 'Thao tác này không thể hồi phục.',
                  cancelText: 'Đóng',
                  confirmText: 'Thực hiện',
                );
              },
              child: const Text('Mở confirm tuỳ biến'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Mở confirm tuỳ biến'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Đóng'), findsOneWidget);
    final buttonFinder = find.widgetWithText(FilledButton, 'Thực hiện');
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(buttonFinder);
    final context = tester.element(buttonFinder);
    final background = button.style?.backgroundColor?.resolve({});
    final foreground = button.style?.foregroundColor?.resolve({});
    expect(background, Theme.of(context).colorScheme.secondary);
    expect(foreground, Theme.of(context).colorScheme.onSecondary);
    await tester.tap(find.widgetWithText(FilledButton, 'Thực hiện'));
    await tester.pumpAndSettle();
    expect(await futureResult, isTrue);
  });

  testWidgets('showAppFormDialog không có onSubmit sẽ không render submit', (
    tester,
  ) async {
    Future<String?>? futureResult;
    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                futureResult = showAppFormDialog<String>(
                  context: context,
                  title: 'Tạo mới',
                  content: const Text('nội dung form'),
                  onSubmit: null,
                );
              },
              child: const Text('Mở form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo mới'), findsOneWidget);
    expect(find.text('nội dung form'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(await futureResult, isNull);
  });

  testWidgets('showAppFormDialog gọi onSubmit khi bấm nút submit', (
    tester,
  ) async {
    Future<String?>? futureResult;
    int submitCalls = 0;

    await tester.pumpWidget(
      _wrapWithMaterial(
        theme: AppTheme.light,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                futureResult = showAppFormDialog<String>(
                  context: context,
                  title: 'Form title',
                  content: const Text('field'),
                  submitText: 'Submit',
                  onSubmit: () {
                    submitCalls += 1;
                    Navigator.of(context).pop('submitted');
                  },
                );
              },
              child: const Text('Mở form submit'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Mở form submit'));
    await tester.pumpAndSettle();
    expect(find.text('Form title'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Submit'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(submitCalls, 1);
    expect(await futureResult, 'submitted');
  });
}
