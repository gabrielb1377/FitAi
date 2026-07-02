import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/treino_service.dart';
import '../../theme/app_theme.dart';
import 'categorias_exercicios_page.dart';

class CriarTreinoPage extends StatefulWidget {
  const CriarTreinoPage({super.key});

  @override
  State<CriarTreinoPage> createState() => _CriarTreinoPageState();
}

class _CriarTreinoPageState extends State<CriarTreinoPage> {
  final formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();

  String objetivo = "Hipertrofia";
  String nivel = "Iniciante";
  int tempo = 45;
  bool salvando = false;

  final List<ExercicioModel> exerciciosSelecionados = [];

  final objetivos = const [
    "Hipertrofia",
    "Emagrecimento",
    "Força",
    "Resistência",
    "Condicionamento",
  ];

  final niveis = const ["Iniciante", "Intermediário", "Avançado"];

  final tempos = const [30, 45, 60, 75, 90];

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  Future<void> _abrirBiblioteca() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CategoriasExerciciosPage(onSelecionar: _adicionarExercicio),
      ),
    );
  }

  void _adicionarExercicio(ExercicioModel exercicio) {
    final jaSelecionado = exerciciosSelecionados.any(
      (item) => item.id == exercicio.id,
    );

    if (jaSelecionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${exercicio.nome} já está na ficha.")),
      );
      return;
    }

    setState(() {
      exerciciosSelecionados.add(exercicio);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${exercicio.nome} adicionado.")));
  }

  void _removerExercicio(ExercicioModel exercicio) {
    setState(() {
      exerciciosSelecionados.removeWhere((item) => item.id == exercicio.id);
    });
  }

  Future<void> _salvarTreino() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (exerciciosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Adicione pelo menos um exercício à ficha."),
        ),
      );
      return;
    }

    if (salvando) return;

    setState(() {
      salvando = true;
    });

    final agora = DateTime.now();
    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();

    final treino = TreinoModel(
      id: "manual_${agora.microsecondsSinceEpoch}",
      nome: nome,
      descricao: descricao.isEmpty
          ? "Ficha manual com ${exerciciosSelecionados.length} exercícios."
          : descricao,
      objetivo: objetivo,
      nivel: nivel,
      tempoEstimado: tempo,
      criadoPorIA: false,
      exercicios: List<ExercicioModel>.from(exerciciosSelecionados),
      dataCriacao: agora.toIso8601String(),
    );

    TreinoService.instance.adicionarTreino(treino);

    if (!mounted) return;

    setState(() {
      salvando = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Treino salvo com sucesso.")));

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Criar treino manual")),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildFormulario(),
            const SizedBox(height: 20),
            _buildAdicionarExercicio(),
            const SizedBox(height: 24),
            _buildExerciciosSelecionados(),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: salvando ? null : _salvarTreino,
              icon: const Icon(Icons.save),
              label: Text(salvando ? "Salvando..." : "Salvar treino"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(26),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monte sua ficha",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${exerciciosSelecionados.length} exercícios selecionados",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return AppGradientCard(
      child: Column(
        children: [
          TextFormField(
            controller: nomeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: "Nome do treino",
              hintText: "Ex: Peito e tríceps",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Digite um nome para o treino.";
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: descricaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Descrição",
              hintText: "Observações rápidas sobre a ficha",
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: objetivo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Objetivo"),
            items: objetivos.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                objetivo = value;
              });
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: nivel,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Nível"),
            items: niveis.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                nivel = value;
              });
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: tempo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Tempo estimado"),
            items: tempos.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text("$item minutos"),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                tempo = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdicionarExercicio() {
    return OutlinedButton.icon(
      onPressed: _abrirBiblioteca,
      icon: const Icon(Icons.library_add),
      label: const Text("Adicionar exercícios"),
    );
  }

  Widget _buildExerciciosSelecionados() {
    return AppSection(
      title: "Exercícios da ficha",
      child: exerciciosSelecionados.isEmpty
          ? AppGradientCard(
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.white70),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Nenhum exercício adicionado ainda.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: exerciciosSelecionados.map((exercicio) {
                return _exercicioSelecionadoCard(exercicio);
              }).toList(),
            ),
    );
  }

  Widget _exercicioSelecionadoCard(ExercicioModel exercicio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGradientCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${exercicio.categoria} • ${exercicio.dificuldade}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              height: 42,
              child: IconButton(
                onPressed: () => _removerExercicio(exercicio),
                tooltip: "Remover",
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
