import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_school_assistant/widgets/analytics_dashboard_widget.dart';
import 'package:smart_school_assistant/widgets/basic_reports_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget Instantiation Tests', () {
    testWidgets('BasicReportsWidget should instantiate without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BasicReportsWidget(),
          ),
        ),
      );

      // Widget should build without throwing errors
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('AnalyticsDashboardWidget should instantiate without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnalyticsDashboardWidget(),
          ),
        ),
      );

      // Widget should build without throwing errors
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('should integrate both widgets in reports tab layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AnalyticsDashboardWidget(),
                  SizedBox(height: 24),
                  BasicReportsWidget(),
                ],
              ),
            ),
          ),
        ),
      );

      // Widgets should build without throwing errors
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      // Verify the layout structure exists
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('Widget Structure Tests', () {
    testWidgets('BasicReportsWidget should have Card structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BasicReportsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain Card widgets (may be empty due to auth)
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('AnalyticsDashboardWidget should have Card structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnalyticsDashboardWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain Card widgets (may be empty due to auth)
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('Performance Tests', () {
    testWidgets('widgets should render within reasonable time',
        (WidgetTester tester) async {
      final startTime = DateTime.now().millisecondsSinceEpoch;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnalyticsDashboardWidget(),
                BasicReportsWidget(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final loadTime = endTime - startTime;

      // Should load within reasonable time (less than 2 seconds for both widgets)
      expect(loadTime, lessThan(2000));

      // No exceptions should be thrown
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('widgets should adapt to different screen sizes',
        (WidgetTester tester) async {
      // Test on mobile screen
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnalyticsDashboardWidget(),
                BasicReportsWidget(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors on mobile
      expect(tester.takeException(), isNull);

      // Test on tablet screen
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnalyticsDashboardWidget(),
                BasicReportsWidget(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors on tablet
      expect(tester.takeException(), isNull);

      // Reset to normal size
      tester.view.resetPhysicalSize();
    });
  });
}
