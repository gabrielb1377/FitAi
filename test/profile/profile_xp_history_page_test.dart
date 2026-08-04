import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/features/profile/presentation/pages/profile_xp_history_page.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra o historico de XP por origem sem ocultar o status local',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FitTheme.dark(),
          home: ProfileXpHistoryPage(snapshot: _snapshot()),
        ),
      );
      await tester.pump();

      expect(find.text('Treino concluido'), findsOneWidget);
      expect(find.text('Corrida concluida'), findsOneWidget);
      expect(find.text('Meta diaria de passos atingida'), findsOneWidget);
      expect(find.textContaining('Salvo localmente'), findsWidgets);

      await tester.tap(find.text('Corridas'));
      await tester.pumpAndSettle();

      expect(find.text('Corrida concluida'), findsOneWidget);
      expect(find.text('Treino concluido'), findsNothing);
      expect(find.text('Meta diaria de passos atingida'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

ProgressionSnapshot _snapshot() {
  final now = DateTime(2026, 8, 3, 12);
  return ProgressionSnapshot(
    schemaVersion: 1,
    userId: 'local',
    version: 1,
    balance: const XpBalance(
      totalXp: 33,
      currentLevel: 1,
      xpIntoCurrentLevel: 33,
      xpForNextLevel: 100,
    ),
    events: [
      _event(
        id: 'workout',
        type: XpSourceType.workout,
        amount: 15,
        reason: 'Treino concluido',
        createdAt: now,
      ),
      _event(
        id: 'running',
        type: XpSourceType.running,
        amount: 10,
        reason: 'Corrida concluida',
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
      _event(
        id: 'steps',
        type: XpSourceType.stepsGoal,
        amount: 8,
        reason: 'Meta diaria de passos atingida',
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
    ],
    achievements: const [],
    goals: const [],
    streaks: const [],
    milestones: const [],
  );
}

XpEvent _event({
  required String id,
  required XpSourceType type,
  required int amount,
  required String reason,
  required DateTime createdAt,
}) => XpEvent(
  id: id,
  userId: 'local',
  sourceType: type,
  sourceId: id,
  amount: amount,
  reason: reason,
  createdAt: createdAt,
  idempotencyKey: 'local:${type.name}:$id',
  syncStatus: ProgressionSyncStatus.local,
  version: 1,
);
