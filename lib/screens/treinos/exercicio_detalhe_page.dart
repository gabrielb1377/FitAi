import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/progressao_service.dart';
import '../../services/storage_service.dart';
import '../../services/treino_service.dart';
import '../../theme/app_theme.dart';
import 'treino_em_andamento_page.dart';
import 'widgets/exercise_hub_widgets.dart';
import 'widgets/exercise_notes_card.dart';

class ExercicioDetalhePage extends StatefulWidget {
  final ExercicioModel exercicio;
  final VoidCallback? onConcluir;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.onConcluir,
  });

  @override
  State<ExercicioDetalhePage> createState() => _ExercicioDetalhePageState();
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage> {
  late Future<ResumoCargaExercicio> _resumoCargaFuture;
  bool _favorito = false;

  ExercicioModel get exercicio => widget.exercicio;

  @override
  void initState() {
    super.initState();
    _resumoCargaFuture = _carregarResumoCarga();
    _carregarFavorito();
  }

  @override
  void didUpdateWidget(covariant ExercicioDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercicio.id != exercicio.id ||
        oldWidget.exercicio.nome != exercicio.nome) {
      _resumoCargaFuture = _carregarResumoCarga();
      _carregarFavorito();
    }
  }

  Future<ResumoCargaExercicio> _carregarResumoCarga() {
    return const ProgressaoService().carregarResumoCarga(exercicio: exercicio);
  }

  Future<void> _carregarFavorito() async {
    final favoritos = await StorageService.carregarFavoritosExercicios();
    if (!mounted) return;

    setState(() {
      _favorito =
          favoritos.contains(_favoritoId) ||
          favoritos.contains(exercicio.id) ||
          favoritos.contains(exercicio.nome);
    });
  }

  Future<void> _alternarFavorito() async {
    final favorito = await StorageService.alternarFavoritoExercicio(
      _favoritoId,
    );
    if (!mounted) return;

    setState(() => _favorito = favorito);
  }

  String get _favoritoId {
    final id = exercicio.id.trim();
    return id.isEmpty ? exercicio.nome.trim() : id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: ExerciseHubExecuteButton(onPressed: _executarAgora),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 118),
                  sliver: SliverList.list(
                    children: [
                      ExerciseHubTopBar(
                        isFavorite: _favorito,
                        onBack: () => Navigator.of(context).maybePop(),
                        onFavorite: _alternarFavorito,
                      ),
                      const SizedBox(height: 16),
                      ExerciseHubHeader(exercicio: exercicio),
                      const SizedBox(height: 14),
                      FutureBuilder<ResumoCargaExercicio>(
                        future: _resumoCargaFuture,
                        builder: (context, snapshot) {
                          final resumo = snapshot.data;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Column(
                              key: ValueKey(snapshot.connectionState),
                              children: [
                                ExerciseCoachCard(resumo: resumo),
                                const SizedBox(height: 14),
                                ExerciseHistoryCard(resumo: resumo),
                                const SizedBox(height: 14),
                                ExerciseStatsCard(resumo: resumo),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      ExerciseNotesCard(exercicio: exercicio),
                      const SizedBox(height: 14),
                      ExerciseTechniqueCard(exercicio: exercicio),
                      const SizedBox(height: 14),
                      ExerciseMusclesCard(exercicio: exercicio),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _executarAgora() {
    if (widget.onConcluir != null) {
      widget.onConcluir!.call();
      return;
    }

    final treino = TreinoModel(
      id: 'treino_rapido_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Treino rapido - ${exercicio.nome}',
      descricao: 'Treino rapido criado a partir do Exercise Hub.',
      objetivo: exercicio.objetivo.trim().isEmpty
          ? 'Treino rapido'
          : exercicio.objetivo,
      nivel: exercicio.dificuldade.trim().isEmpty
          ? 'Livre'
          : exercicio.dificuldade,
      tempoEstimado: 12,
      exercicios: [exercicio],
      criadoPorIA: false,
      dataCriacao: DateTime.now().toIso8601String(),
    );

    TreinoService.instance.adicionarTreino(treino);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TreinoEmAndamentoPage(treino: treino),
      ),
    );
  }
}
