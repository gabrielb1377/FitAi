import 'package:flutter/material.dart';

import '../ai_workout_page.dart';
import 'criar_treino_page.dart';
import 'official/official_plan_editor_page.dart';
import 'ready_plans/ready_plans_library_page.dart';

class CreatePlanPage extends StatelessWidget {
  const CreatePlanPage({
    super.key,
    this.initialDestination = CreatePlanDestination.choice,
  });

  final CreatePlanDestination initialDestination;

  @override
  Widget build(BuildContext context) {
    return switch (initialDestination) {
      CreatePlanDestination.ai => const AIWorkoutPage(),
      CreatePlanDestination.library => const ReadyPlansLibraryPage(),
      CreatePlanDestination.advancedManual => const CriarTreinoPage(),
      CreatePlanDestination.choice ||
      CreatePlanDestination.manual => const OfficialPlanEditorPage(),
    };
  }
}

enum CreatePlanDestination { choice, ai, manual, advancedManual, library }
