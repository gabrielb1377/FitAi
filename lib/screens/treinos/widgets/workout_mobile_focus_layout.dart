import 'package:flutter/material.dart';

import '../../../models/exercicio_model.dart';
import '../../../theme/app_theme.dart';
import 'exercise_history.dart';

class WorkoutMobileFocusLayout extends StatelessWidget {
  final ExercicioModel? exercicio;
  final String title;
  final String elapsedTime;
  final String restText;
  final String seriesText;
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final TextEditingController comentarioController;
  final bool commentOpen;
  final List<ExerciseHistoryEntry> historyEntries;
  final VoidCallback onBack;
  final VoidCallback onRegister;
  final VoidCallback onAddReps;
  final VoidCallback onToggleComment;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onValueChanged;

  const WorkoutMobileFocusLayout({
    super.key,
    required this.exercicio,
    required this.title,
    required this.elapsedTime,
    required this.restText,
    required this.seriesText,
    required this.pesoController,
    required this.repeticoesController,
    required this.comentarioController,
    required this.commentOpen,
    required this.historyEntries,
    required this.onBack,
    required this.onRegister,
    required this.onAddReps,
    required this.onToggleComment,
    required this.onPrevious,
    required this.onNext,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = exercicio;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _Header(title: title, time: elapsedTime, onBack: onBack),
                Expanded(
                  child: item == null
                      ? const _EmptyWorkout()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          physics: const BouncingScrollPhysics(),
                          child: _ExerciseBody(
                            exercicio: item,
                            restText: restText,
                            seriesText: seriesText,
                            pesoController: pesoController,
                            repeticoesController: repeticoesController,
                            comentarioController: comentarioController,
                            commentOpen: commentOpen,
                            historyEntries: historyEntries,
                            onAddReps: onAddReps,
                            onToggleComment: onToggleComment,
                            onValueChanged: onValueChanged,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: item == null ? null : onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Registrar serie',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title, time;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.time,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(time, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  final ExercicioModel exercicio;
  final String restText, seriesText;
  final TextEditingController pesoController, repeticoesController;
  final TextEditingController comentarioController;
  final bool commentOpen;
  final List<ExerciseHistoryEntry> historyEntries;
  final VoidCallback onAddReps, onToggleComment;
  final ValueChanged<String> onValueChanged;

  const _ExerciseBody({
    required this.exercicio,
    required this.restText,
    required this.seriesText,
    required this.pesoController,
    required this.repeticoesController,
    required this.comentarioController,
    required this.commentOpen,
    required this.historyEntries,
    required this.onAddReps,
    required this.onToggleComment,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final reps = repeticoesController.text.trim().isEmpty
        ? '0'
        : repeticoesController.text.trim();
    return Column(
      children: [
        _Gif(path: exercicio.imagem),
        const SizedBox(height: 22),
        Text(
          exercicio.nome,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _recommendation(),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            _Circle(label: 'Repeticoes', value: reps),
            _Circle(label: 'Descanso', value: restText),
            _Circle(label: 'Series', value: seriesText),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _Input(
                label: 'Quilos',
                controller: pesoController,
                onChanged: onValueChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Input(
                label: 'Repeticoes',
                controller: repeticoesController,
                onChanged: onValueChanged,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              height: 56,
              child: FilledButton(
                onPressed: onAddReps,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onToggleComment,
            child: Text(
              commentOpen ? 'Ocultar comentario' : 'Adicionar comentario',
            ),
          ),
        ),
        if (commentOpen)
          _Input(
            label: 'Comentario',
            controller: comentarioController,
            onChanged: onValueChanged,
          ),
        const SizedBox(height: 18),
        _History(entries: historyEntries),
      ],
    );
  }

  String _recommendation() {
    final peso = pesoController.text.trim();
    final carga = peso.isEmpty || peso == '0'
        ? 'carga confortavel'
        : '$peso kg';
    return 'Peso recomendado: $carga. Mantenha controle e amplitude.';
  }
}

class _Gif extends StatelessWidget {
  final String path;
  const _Gif({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 220,
        width: double.infinity,
        color: AppColors.surface,
        child: path.trim().isEmpty
            ? const Icon(Icons.fitness_center, size: 48)
            : Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.fitness_center, size: 48),
              ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label, value;
  const _Circle({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary.withAlpha(120)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _Input({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, filled: true),
    );
  }
}

class _History extends StatelessWidget {
  final List<ExerciseHistoryEntry> entries;
  const _History({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historico', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'Nenhuma serie registrada ainda.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in entries.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_date(item.date)}  Serie ${item.number}: ${item.weight} kg x ${item.repetitions}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
        ],
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _EmptyWorkout extends StatelessWidget {
  const _EmptyWorkout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhum exercicio neste treino.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
