import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/domain/state/app_state.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/screens/error_screen.dart';
import 'package:parfume_app/ui/screens/kvkk_screen/kvkk_screen.dart';
import 'package:parfume_app/ui/screens/loading_screen.dart';
import 'package:parfume_app/ui/screens/plc_error/plc_error_screen.dart';
import 'package:parfume_app/ui/screens/question_screen.dart';
import 'package:parfume_app/ui/screens/result/result_screen.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';
import 'package:parfume_app/data/models/recommendation.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAppViewModel extends Mock implements AppViewModel {}
class MockPLCServiceManager extends Mock implements PLCServiceManager {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [widget] in a minimal [MaterialApp] so widgets that use
/// [Navigator] or [Theme] don't throw during build.
Widget _wrap(Widget widget) => MaterialApp(home: widget);

void main() {
  late MockAppViewModel viewModel;
  late MockPLCServiceManager plcService;
  const router = AppRouter();

  setUp(() {
    viewModel = MockAppViewModel();
    plcService = MockPLCServiceManager();

    // PLCServiceManager her zaman viewModel üzerinden erişiliyor.
    when(() => viewModel.plcService).thenReturn(plcService);
    when(() => viewModel.languageCode).thenReturn('tr');
  });

  // -------------------------------------------------------------------------
  // State → Widget mapping
  // -------------------------------------------------------------------------

  group('state → widget mapping', () {
    testWidgets('InitializingState renders SizedBox.shrink', (tester) async {
      when(() => viewModel.state).thenReturn(const InitializingState());

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      // SizedBox.shrink hiçbir anlamlı widget render etmez.
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(IdleScreen), findsNothing);
    });

    testWidgets('IdleState renders IdleScreen', (tester) async {
      when(() => viewModel.state).thenReturn(const IdleState());

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(IdleScreen), findsOneWidget);
    });

    testWidgets('KvkkState renders KvkkScreen', (tester) async {
      when(() => viewModel.state).thenReturn(const KvkkState());

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(KvkkScreen), findsOneWidget);
    });

    testWidgets('QuestionsState renders QuestionScreen', (tester) async {
      when(() => viewModel.state).thenReturn(const QuestionsState(0));

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(QuestionScreen), findsOneWidget);
    });

    testWidgets('LoadingState renders LoadingScreen', (tester) async {
      when(() => viewModel.state).thenReturn(const LoadingState());

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(LoadingScreen), findsOneWidget);
    });

    testWidgets('ResultState renders ResultScreen', (tester) async {
      when(() => viewModel.state).thenReturn(
        ResultState(Recommendation(topIds: [1, 2, 3])),
      );

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(ResultScreen), findsOneWidget);
    });

    testWidgets('ErrorState renders ErrorScreen', (tester) async {
      when(() => viewModel.state).thenReturn(const ErrorState('test error'));

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(ErrorScreen), findsOneWidget);
    });

    testWidgets('PLCErrorState renders PLCErrorScreen', (tester) async {
      final exception = PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'Connection lost',
      );
      when(() => viewModel.state).thenReturn(PLCErrorState(exception));

      await tester.pumpWidget(_wrap(router.build(viewModel)));

      expect(find.byType(PLCErrorScreen), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // PLCErrorState — onRetry callback
  // -------------------------------------------------------------------------

  group('PLCErrorState onRetry', () {
    late PLCException exception;

    setUp(() {
      exception = PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'Connection lost',
      );
      when(() => viewModel.state).thenReturn(PLCErrorState(exception));
      when(() => plcService.reconnect()).thenAnswer((_) async {});
      when(() => viewModel.resetToIdle()).thenReturn(null);
    });

    testWidgets(
      'reconnect başarılıysa resetToIdle çağrılır',
      (tester) async {
        when(() => plcService.isConnected).thenReturn(true);

        await tester.pumpWidget(_wrap(router.build(viewModel)));

        // PLCErrorScreen'deki onRetry callback'ini doğrudan çağır.
        final screen = tester.widget<PLCErrorScreen>(
          find.byType(PLCErrorScreen),
        );
        await screen.onRetry();

        verify(() => plcService.reconnect()).called(1);
        verify(() => viewModel.resetToIdle()).called(1);
      },
    );

    testWidgets(
      'reconnect başarısızsa resetToIdle çağrılmaz',
      (tester) async {
        when(() => plcService.isConnected).thenReturn(false);

        await tester.pumpWidget(_wrap(router.build(viewModel)));

        final screen = tester.widget<PLCErrorScreen>(
          find.byType(PLCErrorScreen),
        );
        await screen.onRetry();

        verify(() => plcService.reconnect()).called(1);
        verifyNever(() => viewModel.resetToIdle());
      },
    );
  });
}