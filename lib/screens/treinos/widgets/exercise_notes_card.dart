import 'package:flutter/material.dart';

import '../../../models/exercicio_model.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';
import 'exercise_note_dialogs.dart';
import 'exercise_note_widgets.dart';

class ExerciseNotesCard extends StatefulWidget {
  final ExercicioModel exercicio;

  const ExerciseNotesCard({super.key, required this.exercicio});

  @override
  State<ExerciseNotesCard> createState() => _ExerciseNotesCardState();
}

class _ExerciseNotesCardState extends State<ExerciseNotesCard> {
  List<String> _notas = const [];
  bool _carregando = true;

  String get _exercicioId {
    final id = widget.exercicio.id.trim();
    return id.isEmpty ? widget.exercicio.nome.trim() : id;
  }

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  @override
  void didUpdateWidget(covariant ExerciseNotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercicio.id != widget.exercicio.id ||
        oldWidget.exercicio.nome != widget.exercicio.nome) {
      _carregarNotas();
    }
  }

  Future<void> _carregarNotas() async {
    final notas = await StorageService.carregarNotasExercicio(_exercicioId);
    if (!mounted) return;
    setState(() {
      _notas = notas;
      _carregando = false;
    });
  }

  Future<void> _salvarNota({int? index}) async {
    final controller = TextEditingController(
      text: index == null ? '' : _notas[index],
    );
    final texto = await showExerciseNoteEditor(
      context,
      controller: controller,
      editando: index != null,
    );
    controller.dispose();
    if (!mounted || texto == null || texto.trim().isEmpty) return;

    if (index == null) {
      await StorageService.adicionarNotaExercicio(_exercicioId, texto);
    } else {
      await StorageService.editarNotaExercicio(_exercicioId, index, texto);
    }

    if (!mounted) return;
    await _carregarNotas();
  }

  Future<void> _apagarNota(int index) async {
    final confirmar = await showDeleteExerciseNoteConfirm(context);
    if (!mounted || confirmar != true) return;

    await StorageService.removerNotaExercicio(_exercicioId, index);
    if (!mounted) return;
    await _carregarNotas();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseNotesHeader(onAdd: () => _salvarNota()),
          const SizedBox(height: 14),
          if (_carregando)
            const LinearProgressIndicator(minHeight: 6)
          else if (_notas.isEmpty)
            const ExerciseNotesEmptyState()
          else
            for (var index = 0; index < _notas.length; index++) ...[
              ExerciseNoteItem(
                texto: _notas[index],
                onEditar: () => _salvarNota(index: index),
                onApagar: () => _apagarNota(index),
              ),
              if (index != _notas.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withAlpha(16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(38),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}
