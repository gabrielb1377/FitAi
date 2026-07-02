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

  final List<_ExercicioTreinoConfig> exerciciosSelecionados = [];

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
    for (final config in exerciciosSelecionados) {
      config.dispose();
    }
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
      (item) => item.exercicio.id == exercicio.id,
    );

    if (jaSelecionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${exercicio.nome} já está na ficha.")),
      );
      return;
    }

    setState(() {
      exerciciosSelecionados.add(_ExercicioTreinoConfig(exercicio));
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${exercicio.nome} adicionado.")));
  }

  void _removerExercicio(_ExercicioTreinoConfig config) {
    setState(() {
      exerciciosSelecionados.remove(config);
    });

    config.dispose();
  }

  void _moverExercicio(int index, int offset) {
    final novoIndex = index + offset;

    if (novoIndex < 0 || novoIndex >= exerciciosSelecionados.length) {
      return;
    }

    setState(() {
      final item = exerciciosSelecionados.removeAt(index);
      exerciciosSelecionados.insert(novoIndex, item);
    });
  }

  void _alterarSeries(_ExercicioTreinoConfig config, int delta) {
    setState(() {
      config.series = _limitarInteiro(config.series + delta, 1, 12);
    });
  }

  void _alterarRepeticoes(_ExercicioTreinoConfig config, int delta) {
    setState(() {
      config.repeticoes = _limitarInteiro(config.repeticoes + delta, 1, 100);
    });
  }

  void _alterarDescanso(_ExercicioTreinoConfig config, int delta) {
    setState(() {
      config.descansoSegundos = _limitarInteiro(
        config.descansoSegundos + delta,
        0,
        600,
      );
    });
  }

  int _limitarInteiro(int valor, int minimo, int maximo) {
    if (valor < minimo) return minimo;
    if (valor > maximo) return maximo;
    return valor;
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
      exercicios: exerciciosSelecionados.map((item) => item.exercicio).toList(),
      dataCriacao: agora.toIso8601String(),
    );

    await TreinoService.instance.adicionarTreino(treino);

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
            _buildHeader(),
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

  Widget _buildHeader() {
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
                  "Editor de ficha",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${exerciciosSelecionados.length} exercícios configurados",
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
              children: exerciciosSelecionados.asMap().entries.map((entry) {
                return _exercicioSelecionadoCard(
                  config: entry.value,
                  index: entry.key,
                );
              }).toList(),
            ),
    );
  }

  Widget _exercicioSelecionadoCard({
    required _ExercicioTreinoConfig config,
    required int index,
  }) {
    final exercicio = config.exercicio;
    final equipamentoPrincipal = exercicio.equipamentos.isEmpty
        ? "Sem equipamento"
        : exercicio.equipamentos.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGradientCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                  ),
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () => _removerExercicio(config),
                    tooltip: "Remover",
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(exercicio.objetivo),
                _infoChip(equipamentoPrincipal),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _numeroControle(
                    label: "Séries",
                    value: "${config.series}",
                    onMinus: () => _alterarSeries(config, -1),
                    onPlus: () => _alterarSeries(config, 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numeroControle(
                    label: "Reps",
                    value: "${config.repeticoes}",
                    onMinus: () => _alterarRepeticoes(config, -1),
                    onPlus: () => _alterarRepeticoes(config, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _numeroControle(
                    label: "Descanso",
                    value: "${config.descansoSegundos}s",
                    onMinus: () => _alterarDescanso(config, -15),
                    onPlus: () => _alterarDescanso(config, 15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: config.cargaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Carga inicial",
                      suffixText: "kg",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: index == 0
                        ? null
                        : () => _moverExercicio(index, -1),
                    icon: const Icon(Icons.keyboard_arrow_up),
                    label: const Text("Subir"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: index == exerciciosSelecionados.length - 1
                        ? null
                        : () => _moverExercicio(index, 1),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    label: const Text("Descer"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _numeroControle({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniIconButton(
                icon: Icons.remove,
                onPressed: onMinus,
                tooltip: "Diminuir",
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _miniIconButton(
                icon: Icons.add,
                onPressed: onPlus,
                tooltip: "Aumentar",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.primary,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _ExercicioTreinoConfig {
  final ExercicioModel exercicio;
  final TextEditingController cargaController = TextEditingController();
  int series = 3;
  int repeticoes = 10;
  int descansoSegundos = 60;

  _ExercicioTreinoConfig(this.exercicio);

  void dispose() {
    cargaController.dispose();
  }
}
