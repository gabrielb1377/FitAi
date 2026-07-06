import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/treino_service.dart';
import '../../theme/app_theme.dart';
import '../exercicios/biblioteca_exercicios_page.dart';

class CriarTreinoPage extends StatefulWidget {
  const CriarTreinoPage({super.key});

  @override
  State<CriarTreinoPage> createState() => _CriarTreinoPageState();
}

class _DiaManual {
  final int id;
  String diaSemana;
  final TextEditingController tituloController;
  final List<ExercicioModel> exercicios = [];

  _DiaManual({
    required this.id,
    required this.diaSemana,
    required String tituloInicial,
  }) : tituloController = TextEditingController(text: tituloInicial);

  String get titulo {
    final texto = tituloController.text.trim();
    if (texto.isNotEmpty) return texto;

    return "Dia $id";
  }

  void dispose() {
    tituloController.dispose();
  }
}

class _CriarTreinoPageState extends State<CriarTreinoPage> {
  final formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final divisaoPersonalizadaController = TextEditingController();

  String objetivo = "Hipertrofia";
  String nivel = "Iniciante";
  String divisao = "Full Body";
  int tempo = 45;
  bool salvando = false;
  int proximoDiaId = 1;

  final List<_DiaManual> diasPlano = [];

  final objetivos = const [
    "Hipertrofia",
    "Força",
    "Emagrecimento",
    "Resistência",
    "Mobilidade",
  ];

  final niveis = const ["Iniciante", "Intermediário", "Avançado"];

  final divisoes = const [
    "Full Body",
    "AB",
    "ABC",
    "ABCD",
    "ABCDE",
    "Push/Pull/Legs",
    "Superior/Inferior",
    "Personalizado",
  ];

  final tempos = const [30, 45, 60, 75, 90];

  final diasSemana = const [
    "Segunda",
    "Terça",
    "Quarta",
    "Quinta",
    "Sexta",
    "Sábado",
    "Domingo",
  ];

  List<ExercicioModel> get exerciciosSelecionados {
    final porChave = <String, ExercicioModel>{};

    for (final dia in diasPlano) {
      for (final exercicio in dia.exercicios) {
        porChave[_exercicioKey(exercicio)] = exercicio;
      }
    }

    return porChave.values.toList();
  }

  int get totalExerciciosSelecionados {
    return diasPlano.fold<int>(
      0,
      (total, dia) => total + dia.exercicios.length,
    );
  }

  @override
  void initState() {
    super.initState();
    _adicionarDia(inicial: true);
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    divisaoPersonalizadaController.dispose();
    for (final dia in diasPlano) {
      dia.dispose();
    }
    super.dispose();
  }

  String get divisaoSelecionada {
    if (divisao != "Personalizado") return divisao;
    final personalizada = divisaoPersonalizadaController.text.trim();
    return personalizada.isEmpty ? "Personalizado" : personalizada;
  }

  Future<void> _abrirBiblioteca() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BibliotecaExerciciosPage(onSelecionar: _adicionarExercicio),
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

  Future<void> _abrirBibliotecaParaDia(_DiaManual dia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibliotecaExerciciosPage(
          onSelecionar: (exercicio) => _adicionarExercicioAoDia(dia, exercicio),
        ),
      ),
    );
  }

  void _adicionarExercicioAoDia(_DiaManual dia, ExercicioModel exercicio) {
    final chave = _exercicioKey(exercicio);
    final jaSelecionado = dia.exercicios.any(
      (item) => _exercicioKey(item) == chave,
    );

    if (jaSelecionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${exercicio.nome} ja esta neste dia.")),
      );
      return;
    }

    setState(() {
      dia.exercicios.add(exercicio);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${exercicio.nome} adicionado.")));
  }

  void _removerExercicioDoDia(_DiaManual dia, ExercicioModel exercicio) {
    final chave = _exercicioKey(exercicio);

    setState(() {
      dia.exercicios.removeWhere((item) => _exercicioKey(item) == chave);
    });
  }

  void _adicionarDia({bool inicial = false}) {
    setState(() {
      final numero = proximoDiaId++;
      final index = diasPlano.length;
      diasPlano.add(
        _DiaManual(
          id: numero,
          diaSemana: diasSemana[index % diasSemana.length],
          tituloInicial: inicial ? "Full Body" : "Dia $numero",
        ),
      );
    });
  }

  void _removerDia(_DiaManual dia) {
    if (diasPlano.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mantenha pelo menos um dia no plano.")),
      );
      return;
    }

    setState(() {
      diasPlano.remove(dia);
    });

    dia.dispose();
  }

  void _moverDia(int index, int delta) {
    final novoIndex = index + delta;
    if (novoIndex < 0 || novoIndex >= diasPlano.length) return;

    setState(() {
      final dia = diasPlano.removeAt(index);
      diasPlano.insert(novoIndex, dia);
    });
  }

  List<TreinoDiaModel> _montarDiasTreino() {
    return List.generate(diasPlano.length, (index) {
      final dia = diasPlano[index];

      return TreinoDiaModel(
        codigo: dia.diaSemana,
        nome: dia.titulo,
        ordem: index + 1,
        exercicioIds: dia.exercicios.map(_exercicioKey).toList(),
      );
    });
  }

  String _exercicioKey(ExercicioModel exercicio) {
    final id = exercicio.id.trim();
    if (id.isNotEmpty) return id;

    return exercicio.nome.trim();
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

    if (divisao == "Personalizado" &&
        divisaoPersonalizadaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe a divisao personalizada.")),
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
    final divisaoTreino = divisaoSelecionada;
    final diasSalvos = _montarDiasTreino();

    final treino = TreinoModel(
      id: "manual_${agora.microsecondsSinceEpoch}",
      nome: nome,
      descricao: descricao.isEmpty
          ? "Ficha manual com ${exerciciosSelecionados.length} exercícios."
          : descricao,
      objetivo: objetivo,
      nivel: nivel,
      divisao: divisaoTreino,
      tempoEstimado: tempo,
      diasPorSemana: diasSalvos.length,
      planoDias: diasSalvos,
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
            _buildDiasPlano(),
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
            initialValue: divisao,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Tipo de treino"),
            items: divisoes.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                divisao = value;
              });
            },
          ),
          if (divisao == "Personalizado") ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: divisaoPersonalizadaController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Divisao personalizada",
                hintText: "Ex: A Peito, B Costas, C Pernas",
              ),
            ),
          ],
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

  // ignore: unused_element
  Widget _buildAdicionarExercicio() {
    return OutlinedButton.icon(
      onPressed: _abrirBiblioteca,
      icon: const Icon(Icons.library_add),
      label: const Text("Adicionar exercícios"),
    );
  }

  // ignore: unused_element
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

  Widget _buildDiasPlano() {
    return AppSection(
      title: "Dias do plano",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < diasPlano.length; index++) ...[
            _buildDiaPlanoCard(diasPlano[index], index),
            const SizedBox(height: 14),
          ],
          OutlinedButton.icon(
            onPressed: () => _adicionarDia(),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Adicionar dia"),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaPlanoCard(_DiaManual dia, int index) {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Dia ${index + 1}",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: index == 0 ? null : () => _moverDia(index, -1),
                tooltip: "Subir dia",
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                onPressed: index == diasPlano.length - 1
                    ? null
                    : () => _moverDia(index, 1),
                tooltip: "Descer dia",
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              IconButton(
                onPressed: () => _removerDia(dia),
                tooltip: "Remover dia",
                color: Colors.redAccent,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: dia.diaSemana,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Dia da semana"),
            items: diasSemana.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                dia.diaSemana = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dia.tituloController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: "Grupo muscular / titulo",
              hintText: "Ex: Peito + Triceps",
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _abrirBibliotecaParaDia(dia),
            icon: const Icon(Icons.library_add_rounded),
            label: const Text("Adicionar exercicios neste dia"),
          ),
          const SizedBox(height: 14),
          if (dia.exercicios.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white60),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Nenhum exercicio neste dia.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < dia.exercicios.length; i++) ...[
                  _exercicioDiaCard(dia, dia.exercicios[i], i),
                  if (i < dia.exercicios.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _exercicioDiaCard(
    _DiaManual dia,
    ExercicioModel exercicio,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${exercicio.categoria} | ${exercicio.dificuldade}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: () => _removerExercicioDoDia(dia, exercicio),
              tooltip: "Remover exercicio",
              color: Colors.redAccent,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
