import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/ai_chat/application/ai_chat_controller.dart';
import 'package:fitai/features/ai_chat/data/ai_chat_gateway.dart';
import 'package:fitai/features/ai_chat/data/ai_chat_repository.dart';
import 'package:fitai/features/ai_chat/domain/ai_chat_models.dart';
import 'package:fitai/features/ai_chat/presentation/ai_chat_page.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/home/presentation/pages/home_coach_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthSession session(String owner) => AuthSession(
  userId: owner,
  name: owner,
  email: '$owner@fitia.test',
  token: 'fixture-token',
);

class FakeGateway implements AiChatGateway {
  final requests = <Map<String, dynamic>>[];
  AiChatFailure? failure;
  Completer<AiChatReply>? delayed;
  @override
  Future<AiChatReply> send({
    required String userId,
    required Map<String, dynamic> input,
  }) async {
    requests.add(Map.from(input));
    if (failure != null) throw failure!;
    if (delayed != null) return delayed!.future;
    return reply;
  }
}

const reply = AiChatReply(
  conversationId: 'conversation-a',
  userMessageId: 'user-message-a',
  messageId: 'assistant-a',
  content: 'Sua corrida registrada mostra consistencia.',
);
AiChatController controller(FakeGateway gateway, [String owner = 'a']) =>
    AiChatController(
      repository: AiChatRepository(gateway: gateway),
      session: () async => session(owner),
    );

class FakeAuth extends AuthService {
  AuthSession? current = session('a');
  int refreshed = 0;
  @override
  Future<AuthSession?> restoreSession() async => current;
  @override
  Future<AuthSession?> refreshSession({AuthSession? session}) async {
    refreshed++;
    return current;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('a');
  });
  tearDown(() {
    AccountSessionLifecycle.setActiveUser(null);
    ApiConfig.reset();
  });

  Future<void> host(WidgetTester tester, AiChatController c) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AiChatPage(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(c.dispose);
  }

  Future<void> sendUi(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Como foi minha corrida?');
    await tester.tap(find.byTooltip('Enviar mensagem'));
    await tester.pump();
  }

  testWidgets('AI-UI-01 empty state and named composer', (tester) async {
    await host(tester, controller(FakeGateway()));
    expect(find.text('Converse sobre seu treino'), findsOneWidget);
    expect(find.text('Mensagem para o Coach'), findsOneWidget);
  });
  testWidgets('AI-UI-02/04 send and render assistant', (tester) async {
    final gateway = FakeGateway();
    await host(tester, controller(gateway));
    await sendUi(tester);
    await tester.pumpAndSettle();
    expect(gateway.requests.single['message'], 'Como foi minha corrida?');
    expect(find.text(reply.content), findsOneWidget);
  });
  testWidgets('AI-UI-03 loading retains pending message and disables send', (
    tester,
  ) async {
    final gateway = FakeGateway()..delayed = Completer();
    await host(tester, controller(gateway));
    await sendUi(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Aguardando resposta'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    gateway.delayed!.complete(reply);
    await tester.pumpAndSettle();
  });
  testWidgets('AI-UI-05 retry uses original logical ID', (tester) async {
    final gateway = FakeGateway()
      ..failure = const AiChatFailure('timeout', 'Demorou.', retryable: true);
    await host(tester, controller(gateway));
    await sendUi(tester);
    await tester.pumpAndSettle();
    gateway.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(gateway.requests[0], gateway.requests[1]);
    expect(find.text(reply.content), findsOneWidget);
  });
  testWidgets('AI-UI-06 quota does not offer unsafe retry', (tester) async {
    final gateway = FakeGateway()
      ..failure = const AiChatFailure('quota', 'Limite diario atingido.');
    await host(tester, controller(gateway));
    await sendUi(tester);
    await tester.pumpAndSettle();
    expect(find.text('Limite diario atingido.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });
  testWidgets('AI-UI-07 offline retains transcript and pending draft', (
    tester,
  ) async {
    final gateway = FakeGateway(), c = controller(gateway);
    await host(tester, c);
    await sendUi(tester);
    await tester.pumpAndSettle();
    gateway.failure = const AiChatFailure(
      'offline',
      'Sem conexao.',
      retryable: true,
    );
    await sendUi(tester);
    await tester.pumpAndSettle();
    expect(find.text(reply.content), findsOneWidget);
    expect(find.text('Mensagem pendente'), findsOneWidget);
    expect(find.text('Sem conexao.'), findsOneWidget);
  });
  testWidgets('AI-UI-08 new conversation clears old UI/history', (
    tester,
  ) async {
    final gateway = FakeGateway();
    await host(tester, controller(gateway));
    await sendUi(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nova conversa'));
    await tester.pumpAndSettle();
    expect(find.text(reply.content), findsNothing);
    await sendUi(tester);
    await tester.pumpAndSettle();
    expect(gateway.requests.last.containsKey('conversationId'), false);
  });
  test('AI-UI-09 double send cannot duplicate pending request', () async {
    final gateway = FakeGateway()..delayed = Completer(),
        c = controller(gateway);
    addTearDown(c.dispose);
    await c.initialize();
    final first = c.send('ola');
    await c.send('ola');
    await Future<void>.delayed(Duration.zero);
    expect(gateway.requests.length, 1);
    gateway.delayed!.complete(reply);
    await first;
    expect(c.messages.length, 2);
  });
  testWidgets(
    'AI-UI-10 Coach entry preserved even without insights; back restores origin',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const HomeCoachPage(initialInsights: []),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conversar com Coach'));
      await tester.pumpAndSettle();
      expect(find.byType(AiChatPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(AiChatPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeCoachPage), findsOneWidget);
      expect(find.byType(AiChatPage), findsNothing);
    },
  );
  testWidgets(
    'Coach menu closes before opening chat and back returns to origin',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const HomeCoachPage(initialInsights: []),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais opções do Coach'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conversar com Coach').last);
      await tester.pumpAndSettle();
      expect(find.byType(AiChatPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(AiChatPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeCoachPage), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );
  test(
    'cache persists completed and pending messages through controller restart',
    () async {
      final gateway = FakeGateway(), first = controller(gateway);
      await first.initialize();
      await first.send('ola');
      first.dispose();
      gateway.failure = const AiChatFailure(
        'offline',
        'Offline',
        retryable: true,
      );
      final second = controller(gateway);
      await second.initialize();
      expect(second.messages.length, 2);
      await second.send('outra');
      final key = second.pending!['clientRequestId'];
      second.dispose();
      final third = controller(gateway);
      addTearDown(third.dispose);
      await third.initialize();
      expect(third.messages.length, 2);
      expect(third.pending!['clientRequestId'], key);
    },
  );
  test(
    'account switch discards late response, isolates caches, preserves A data',
    () async {
      final gateway = FakeGateway()..delayed = Completer(),
          a = controller(gateway);
      await a.initialize();
      final pending = a.send('private-A');
      await Future<void>.delayed(Duration.zero);
      AccountSessionLifecycle.setActiveUser('b');
      gateway.delayed!.complete(reply);
      await pending;
      expect(a.messages, isEmpty);
      expect(a.ready, false);
      a.dispose();
      final b = controller(gateway, 'b');
      await b.initialize();
      expect(b.messages, isEmpty);
      b.dispose();
      AccountSessionLifecycle.setActiveUser('a');
      final restored = controller(gateway);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.pending!['message'], 'private-A');
    },
  );
  test('initialization rejects stale session after account switch', () async {
    final delayed = Completer<AuthSession?>();
    final c = AiChatController(
      repository: AiChatRepository(gateway: FakeGateway()),
      session: () => delayed.future,
    );
    addTearDown(c.dispose);
    final initialization = c.initialize();
    AccountSessionLifecycle.setActiveUser('b');
    delayed.complete(session('a'));
    await initialization;
    expect(c.ready, false);
    expect(c.messages, isEmpty);
  });
  test('initialization rejects stale session after logout', () async {
    final delayed = Completer<AuthSession?>();
    final c = AiChatController(
      repository: AiChatRepository(gateway: FakeGateway()),
      session: () => delayed.future,
    );
    addTearDown(c.dispose);
    final initialization = c.initialize();
    AccountSessionLifecycle.setActiveUser(null);
    delayed.complete(session('a'));
    await initialization;
    expect(c.ready, false);
    expect(c.messages, isEmpty);
  });
  test(
    'gateway uses JWT, one refresh, stable request and read-only validation',
    () async {
      ApiConfig.configure(baseUrl: 'https://api.fitia.test');
      final auth = FakeAuth();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.headers['Authorization'], 'Bearer fixture-token');
        final body = jsonDecode(request.body) as Map;
        expect(body.containsKey('userId'), false);
        if (calls == 1) return http.Response('{}', 401);
        return http.Response(
          jsonEncode({
            'contractVersion': AiChatContract.version,
            'clientRequestId': body['clientRequestId'],
            'conversationId': reply.conversationId,
            'messageId': reply.messageId,
            'userMessageId': reply.userMessageId,
            'content': reply.content,
            'capabilities': [],
          }),
          200,
        );
      });
      final gateway = HttpAiChatGateway(client: client, auth: auth);
      addTearDown(gateway.dispose);
      expect(
        (await gateway.send(
          userId: 'a',
          input: {'message': 'ola', 'clientRequestId': 'request-1'},
        )).content,
        reply.content,
      );
      expect(auth.refreshed, 1);
      expect(calls, 2);
      auth.current = session('b');
      await expectLater(
        gateway.send(userId: 'a', input: {}),
        throwsA(isA<AiChatFailure>()),
      );
      expect(calls, 2);
    },
  );
  test(
    'gateway hides provider errors and fails closed on mutable response',
    () async {
      ApiConfig.configure(baseUrl: 'https://api.fitia.test');
      var mutable = false;
      final gateway = HttpAiChatGateway(
        auth: FakeAuth(),
        client: MockClient(
          (_) async => mutable
              ? http.Response(
                  jsonEncode({
                    'contractVersion': AiChatContract.version,
                    'clientRequestId': 'request-1',
                    'conversationId': 'c',
                    'messageId': 'm',
                    'userMessageId': 'u',
                    'content': 'x',
                    'capabilities': ['mutate'],
                  }),
                  200,
                )
              : http.Response(
                  '{"code":"ai_not_configured","message":"SECRET private-provider"}',
                  503,
                ),
        ),
      );
      addTearDown(gateway.dispose);
      final input = {'message': 'ola', 'clientRequestId': 'request-1'};
      await expectLater(
        gateway.send(userId: 'a', input: input),
        throwsA(
          isA<AiChatFailure>().having(
            (e) => e.code,
            'code',
            'ai_not_configured',
          ),
        ),
      );
      mutable = true;
      await expectLater(
        gateway.send(userId: 'a', input: input),
        throwsA(
          isA<AiChatFailure>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('chat responsive ${width.toInt()} at text 200%', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = controller(FakeGateway());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AiChatPage(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await sendUi(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      addTearDown(c.dispose);
    });
  }
}
