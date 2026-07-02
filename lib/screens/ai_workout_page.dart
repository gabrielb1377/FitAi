import 'dart:math';

import 'package:flutter/material.dart';

import '../data/exercicios/exercicios.dart';
import '../models/exercicio_model.dart';
import '../models/treino_model.dart';
import '../services/treino_service.dart';
import '../theme/app_theme.dart';

class _TreinoFichaConfig {
  final String nome;
  final List<String> focos;

  const _TreinoFichaConfig({required this.nome, required this.focos});
}

class _FichaSemanalConfig {
  final String tipo;
  final String descricao;
  final List<_TreinoFichaConfig> treinos;

  const _FichaSemanalConfig({
    required this.tipo,
    required this.descricao,
    required this.treinos,
  });
}

class AIWorkoutPage extends StatefulWidget {
  const AIWorkoutPage({super.key});

  @override
  State<AIWorkoutPage> createState() => _AIWorkoutPageState();
}

class _AIWorkoutPageState extends State<AIWorkoutPage> {
  static const _tipoTreinoUnico = 'Treino único';
  static const _tipoAbc = 'ABC';
  static const _tipoAbcd = 'ABCD';
  static const _tipoAbcde = 'ABCDE';
  static const _tipoPushPullLegs = 'Push Pull Legs';
  static const _tipoFullBody = 'Full Body';

  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  final idadeController = TextEditingController();
  final treinoService = TreinoService.instance;

  String experiencia = 'Iniciante';
  String objetivo = 'Hipertrofia';
  String tipoFicha = _tipoTreinoUnico;
  int diasPorSemana = 3;
  bool carregando = false;

  final objetivos = const [
    'Hipertrofia',
    'Emagrecimento',
    'Resistência',
    'Calistenia',
    'Força',
  ];

  final experiencias = const ['Iniciante', 'Intermediário', 'Avançado'];
  final tiposFicha = const [
    _tipoTreinoUnico,
    _tipoAbc,
    _tipoAbcd,
    _tipoAbcde,
    _tipoPushPullLegs,
    _tipoFullBody,
  ];
  final opcoesDiasPorSemana = const [3, 4, 5, 6];

  @override
  void dispose() {
    pesoController.dispose();
    alturaController.dispose();
    idadeController.dispose();
    super.dispose();
  }

  Future<void> _gerarTreino() async {
    if (carregando) return;

    setState(() {
      carregando = true;
    });

    try {
      final mensagem = tipoFicha == _tipoTreinoUnico
          ? await _salvarTreinoUnico()
          : await _salvarFichaSemanal();

      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));

      Navigator.pop(context, true);
    } catch (erro) {
      debugPrint('Erro ao gerar treino IA: $erro');

      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o treino agora.')),
      );
    }
  }

  Future<String> _salvarTreinoUnico() async {
    final exercicios = _selecionarExerciciosInteligentes();
    final agora = DateTime.now();

    final treino = _montarTreino(
      id: 'ia_${agora.microsecondsSinceEpoch}',
      nome: 'Treino $objetivo',
      descricao: _descricaoTreino(exercicios.length),
      exercicios: exercicios,
      dataCriacao: agora,
    );

    await treinoService.adicionarTreino(treino);

    return 'Treino gerado com sucesso!';
  }

  Future<String> _salvarFichaSemanal() async {
    final ficha = _fichaSelecionada();

    if (ficha == null) {
      return _salvarTreinoUnico();
    }

    final agora = DateTime.now();
    final idsUsadosNaFicha = <String>{};

    for (var index = 0; index < ficha.treinos.length; index++) {
      final dia = ficha.treinos[index];
      final exercicios = _selecionarExerciciosInteligentes(
        focos: dia.focos,
        idsPreferencialmenteEvitados: idsUsadosNaFicha,
      );
      final dataCriacao = agora.subtract(Duration(milliseconds: index));

      idsUsadosNaFicha.addAll(exercicios.map((exercicio) => exercicio.id));

      final treino = _montarTreino(
        id: 'ia_${agora.microsecondsSinceEpoch}_$index',
        nome: dia.nome,
        descricao: _descricaoTreino(
          exercicios.length,
          nomeFicha: ficha.tipo,
          focos: dia.focos,
        ),
        exercicios: exercicios,
        dataCriacao: dataCriacao,
      );

      await treinoService.adicionarTreino(treino);
    }

    return 'Ficha ${ficha.tipo} gerada com sucesso!';
  }

  TreinoModel _montarTreino({
    required String id,
    required String nome,
    required String descricao,
    required List<ExercicioModel> exercicios,
    required DateTime dataCriacao,
  }) {
    return TreinoModel(
      id: id,
      nome: nome,
      descricao: descricao,
      objetivo: objetivo,
      nivel: experiencia,
      tempoEstimado: exercicios.length * 8,
      criadoPorIA: true,
      exercicios: exercicios,
      dataCriacao: dataCriacao.toIso8601String(),
    );
  }

  String _descricaoTreino(
    int totalExercicios, {
    String? nomeFicha,
    List<String> focos = const [],
  }) {
    final dados = <String>[];

    if (pesoController.text.trim().isNotEmpty) {
      dados.add('${pesoController.text.trim()} kg');
    }

    if (alturaController.text.trim().isNotEmpty) {
      dados.add('${alturaController.text.trim()} cm');
    }

    if (idadeController.text.trim().isNotEmpty) {
      dados.add('${idadeController.text.trim()} anos');
    }

    final dadosTexto = dados.isEmpty
        ? ''
        : ' Dados usados: ${dados.join(', ')}.';
    final fichaTexto = nomeFicha == null
        ? 'Treino único'
        : 'Ficha $nomeFicha com $diasPorSemana dias por semana';
    final focoTexto = focos.isEmpty ? '' : ' Foco: ${focos.join(', ')}.';

    return '$fichaTexto gerado com $totalExercicios exercícios do banco FitIA, priorizando $objetivo e nível $experiencia.$focoTexto$dadosTexto';
  }

  _FichaSemanalConfig? _fichaSelecionada() {
    switch (tipoFicha) {
      case _tipoAbc:
        return const _FichaSemanalConfig(
          tipo: _tipoAbc,
          descricao: 'Divisão clássica em 3 treinos: empurrar, puxar e pernas.',
          treinos: [
            _TreinoFichaConfig(
              nome: 'A - Peito + Tríceps',
              focos: ['Peito', 'Tríceps'],
            ),
            _TreinoFichaConfig(
              nome: 'B - Costas + Bíceps',
              focos: ['Costas', 'Bíceps'],
            ),
            _TreinoFichaConfig(
              nome: 'C - Pernas + Glúteos',
              focos: ['Pernas', 'Panturrilha', 'Glúteos'],
            ),
          ],
        );
      case _tipoAbcd:
        return const _FichaSemanalConfig(
          tipo: _tipoAbcd,
          descricao:
              'Quatro treinos com grupos maiores separados e braços no fim.',
          treinos: [
            _TreinoFichaConfig(nome: 'A - Peito', focos: ['Peito']),
            _TreinoFichaConfig(nome: 'B - Costas', focos: ['Costas']),
            _TreinoFichaConfig(
              nome: 'C - Pernas + Glúteos',
              focos: ['Pernas', 'Glúteos'],
            ),
            _TreinoFichaConfig(
              nome: 'D - Ombros + Braços',
              focos: ['Ombros', 'Bíceps', 'Tríceps'],
            ),
          ],
        );
      case _tipoAbcde:
        return const _FichaSemanalConfig(
          tipo: _tipoAbcde,
          descricao: 'Cinco treinos com foco mais específico por sessão.',
          treinos: [
            _TreinoFichaConfig(nome: 'A - Peito', focos: ['Peito']),
            _TreinoFichaConfig(nome: 'B - Costas', focos: ['Costas']),
            _TreinoFichaConfig(nome: 'C - Pernas', focos: ['Pernas']),
            _TreinoFichaConfig(nome: 'D - Ombros', focos: ['Ombros']),
            _TreinoFichaConfig(
              nome: 'E - Bíceps + Tríceps',
              focos: ['Bíceps', 'Tríceps'],
            ),
          ],
        );
      case _tipoPushPullLegs:
        return const _FichaSemanalConfig(
          tipo: _tipoPushPullLegs,
          descricao:
              'Push Pull Legs organiza empurrar, puxar e pernas em blocos claros.',
          treinos: [
            _TreinoFichaConfig(
              nome: 'Push - Peito + Ombros + Tríceps',
              focos: ['Peito', 'Ombros', 'Tríceps'],
            ),
            _TreinoFichaConfig(
              nome: 'Pull - Costas + Bíceps',
              focos: ['Costas', 'Bíceps'],
            ),
            _TreinoFichaConfig(
              nome: 'Legs - Pernas + Glúteos + Panturrilha',
              focos: ['Pernas', 'Glúteos', 'Panturrilha'],
            ),
          ],
        );
      case _tipoFullBody:
        return const _FichaSemanalConfig(
          tipo: _tipoFullBody,
          descricao:
              'Três full body diferentes para treinar o corpo inteiro na semana.',
          treinos: [
            _TreinoFichaConfig(
              nome: 'Full Body A',
              focos: ['Peito', 'Costas', 'Pernas', 'Abdômen'],
            ),
            _TreinoFichaConfig(
              nome: 'Full Body B',
              focos: ['Ombros', 'Costas', 'Glúteos', 'Pernas'],
            ),
            _TreinoFichaConfig(
              nome: 'Full Body C',
              focos: ['Peito', 'Funcional', 'Pernas', 'Abdômen'],
            ),
          ],
        );
      default:
        return null;
    }
  }

  List<ExercicioModel> _selecionarExerciciosInteligentes({
    List<String> focos = const [],
    Set<String>? idsPreferencialmenteEvitados,
  }) {
    final random = Random(
      DateTime.now().microsecondsSinceEpoch + focos.join('|').hashCode,
    );
    final quantidadeDesejada = 5 + random.nextInt(4);
    final selecionados = <ExercicioModel>[];
    final idsSelecionados = <String>{};
    final categorias = _categoriasPrioritarias(objetivo);

    void adicionarCandidatos(
      Iterable<ExercicioModel> candidatos, {
      required bool evitarGlobais,
    }) {
      if (selecionados.length >= quantidadeDesejada) return;

      final lista = candidatos.where((exercicio) {
        if (idsSelecionados.contains(exercicio.id)) return false;

        final deveEvitarGlobal =
            evitarGlobais &&
            idsPreferencialmenteEvitados?.contains(exercicio.id) == true;

        return !deveEvitarGlobal;
      }).toList()..shuffle(random);

      for (final exercicio in lista) {
        if (selecionados.length >= quantidadeDesejada) return;

        if (idsSelecionados.add(exercicio.id)) {
          selecionados.add(exercicio);
        }
      }
    }

    void preencher({required bool evitarGlobais}) {
      if (focos.isNotEmpty) {
        adicionarCandidatos(
          bancoExercicios.where((exercicio) {
            return _combinaFocos(exercicio, focos) &&
                _combinaObjetivo(exercicio, objetivo) &&
                _combinaDificuldade(exercicio, experiencia);
          }),
          evitarGlobais: evitarGlobais,
        );

        adicionarCandidatos(
          bancoExercicios.where((exercicio) {
            return _combinaFocos(exercicio, focos) &&
                _combinaObjetivo(exercicio, objetivo);
          }),
          evitarGlobais: evitarGlobais,
        );

        adicionarCandidatos(
          bancoExercicios.where((exercicio) {
            return _combinaFocos(exercicio, focos) &&
                _combinaDificuldade(exercicio, experiencia);
          }),
          evitarGlobais: evitarGlobais,
        );

        adicionarCandidatos(
          bancoExercicios.where((exercicio) => _combinaFocos(exercicio, focos)),
          evitarGlobais: evitarGlobais,
        );
      }

      adicionarCandidatos(
        bancoExercicios.where((exercicio) {
          return _combinaObjetivo(exercicio, objetivo) &&
              _combinaDificuldade(exercicio, experiencia) &&
              _combinaCategoriaPrioritaria(exercicio, categorias);
        }),
        evitarGlobais: evitarGlobais,
      );

      adicionarCandidatos(
        bancoExercicios.where(
          (exercicio) => _combinaObjetivo(exercicio, objetivo),
        ),
        evitarGlobais: evitarGlobais,
      );

      adicionarCandidatos(
        bancoExercicios.where((exercicio) {
          return _combinaCategoriaPrioritaria(exercicio, categorias) &&
              _combinaDificuldade(exercicio, experiencia);
        }),
        evitarGlobais: evitarGlobais,
      );

      adicionarCandidatos(
        bancoExercicios.where(
          (exercicio) => _combinaCategoriaPrioritaria(exercicio, categorias),
        ),
        evitarGlobais: evitarGlobais,
      );

      if (_priorizaPesoCorporal(objetivo)) {
        adicionarCandidatos(
          bancoExercicios.where(_ehPesoCorporal),
          evitarGlobais: evitarGlobais,
        );
      }

      adicionarCandidatos(
        bancoExercicios.where(
          (exercicio) => _combinaDificuldade(exercicio, experiencia),
        ),
        evitarGlobais: evitarGlobais,
      );

      adicionarCandidatos(bancoExercicios, evitarGlobais: evitarGlobais);
    }

    preencher(evitarGlobais: true);

    if (selecionados.length < quantidadeDesejada &&
        idsPreferencialmenteEvitados != null &&
        idsPreferencialmenteEvitados.isNotEmpty) {
      preencher(evitarGlobais: false);
    }

    return selecionados;
  }

  List<String> _categoriasPrioritarias(String objetivo) {
    switch (_normalizar(objetivo)) {
      case 'emagrecimento':
        return const ['Cardio', 'Funcional', 'Pernas', 'Abdômen'];
      case 'resistencia':
        return const ['Cardio', 'Funcional', 'Abdômen'];
      case 'calistenia':
        return const ['Funcional', 'Abdômen', 'Peito', 'Costas'];
      case 'forca':
        return const ['Pernas', 'Costas', 'Peito', 'Ombros'];
      case 'hipertrofia':
      default:
        return const [
          'Peito',
          'Costas',
          'Pernas',
          'Ombros',
          'Bíceps',
          'Tríceps',
          'Glúteos',
        ];
    }
  }

  bool _combinaCategoriaPrioritaria(
    ExercicioModel exercicio,
    List<String> categorias,
  ) {
    final categoria = _normalizar(exercicio.categoria);

    return categorias.any((item) => _normalizar(item) == categoria);
  }

  bool _combinaFocos(ExercicioModel exercicio, List<String> focos) {
    if (focos.isEmpty) return true;

    final textoBusca = [
      exercicio.nome,
      exercicio.categoria,
      ...exercicio.musculos,
      ...exercicio.musculosSecundarios,
      ...exercicio.tags,
    ].map(_normalizar).join(' ');

    final termos = focos.expand(_termosRelacionados).toSet();

    return termos.any(textoBusca.contains);
  }

  List<String> _termosRelacionados(String foco) {
    final valor = _normalizar(foco);

    switch (valor) {
      case 'peito':
        return const ['peito', 'peitoral'];
      case 'costas':
        return const [
          'costas',
          'dorso',
          'dorsal',
          'latissimo',
          'romboide',
          'trapezio',
        ];
      case 'pernas':
        return const [
          'pernas',
          'quadriceps',
          'isquiotibiais',
          'posterior',
          'adutor',
          'abdutor',
        ];
      case 'ombros':
        return const ['ombros', 'deltoide'];
      case 'biceps':
        return const ['biceps', 'braquial'];
      case 'triceps':
        return const ['triceps'];
      case 'bracos':
        return const ['bracos', 'biceps', 'triceps', 'antebraco'];
      case 'gluteos':
        return const ['gluteos', 'gluteo'];
      case 'panturrilha':
        return const ['panturrilha', 'gastrocnemio', 'soleo'];
      case 'abdomen':
        return const ['abdomen', 'abdominal', 'core', 'obliquos'];
      case 'funcional':
        return const ['funcional', 'condicionamento'];
      case 'cardio':
        return const ['cardio', 'condicionamento', 'aerobico'];
      default:
        return [valor];
    }
  }

  bool _priorizaPesoCorporal(String objetivo) {
    final valor = _normalizar(objetivo);
    return valor == 'resistencia' || valor == 'calistenia';
  }

  bool _combinaObjetivo(ExercicioModel exercicio, String objetivoSelecionado) {
    final objetivoNormalizado = _normalizar(objetivoSelecionado);
    final objetivoExercicio = _normalizar(exercicio.objetivo);
    final tags = exercicio.tags.map(_normalizar).toList();

    if (objetivoExercicio.contains(objetivoNormalizado)) return true;
    if (tags.any((tag) => tag.contains(objetivoNormalizado))) return true;

    if (objetivoNormalizado == 'calistenia') {
      return _ehPesoCorporal(exercicio) ||
          tags.any((tag) => tag.contains('calistenia'));
    }

    if (objetivoNormalizado == 'resistencia') {
      return objetivoExercicio.contains('condicionamento') ||
          tags.any((tag) => tag.contains('resistencia'));
    }

    if (objetivoNormalizado == 'hipertrofia') {
      return objetivoExercicio.contains('hipertrofia') ||
          tags.any((tag) => tag.contains('hipertrofia'));
    }

    if (objetivoNormalizado == 'emagrecimento') {
      return objetivoExercicio.contains('definicao') ||
          objetivoExercicio.contains('condicionamento') ||
          tags.any((tag) {
            return tag.contains('cardio') ||
                tag.contains('definicao') ||
                tag.contains('emagrecimento');
          });
    }

    if (objetivoNormalizado == 'forca') {
      return objetivoExercicio.contains('forca') ||
          tags.any((tag) => tag.contains('forca'));
    }

    return false;
  }

  bool _combinaDificuldade(
    ExercicioModel exercicio,
    String experienciaSelecionada,
  ) {
    return _normalizar(exercicio.dificuldade) ==
        _normalizar(experienciaSelecionada);
  }

  bool _ehPesoCorporal(ExercicioModel exercicio) {
    final equipamentos = exercicio.equipamentos.map(_normalizar).toList();
    final tags = exercicio.tags.map(_normalizar).toList();

    return exercicio.equipamentos.isEmpty ||
        equipamentos.any((item) => item.contains('peso corporal')) ||
        tags.any((tag) {
          return tag.contains('peso corporal') ||
              tag.contains('sem equipamento') ||
              tag.contains('calistenia');
        });
  }

  String _normalizar(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ã¡': 'a',
      'ã ': 'a',
      'ã¢': 'a',
      'ã£': 'a',
      'ã©': 'e',
      'ãª': 'e',
      'ã­': 'i',
      'ã³': 'o',
      'ã´': 'o',
      'ãµ': 'o',
      'ãº': 'u',
      'ã¼': 'u',
      'ã§': 'c',
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Gerador de Treino IA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildFormulario(),
          const SizedBox(height: 20),
          _buildDivisaoCard(),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: carregando ? null : _gerarTreino,
            icon: carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              carregando
                  ? 'Montando ficha...'
                  : tipoFicha == _tipoTreinoUnico
                  ? 'Gerar Treino Inteligente'
                  : 'Gerar Ficha Inteligente',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Treino com IA', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Informe seu perfil e deixe o FitIA montar um treino avulso ou uma ficha semanal com exercícios reais da biblioteca.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banco real de exercícios',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'A seleção combina objetivo, experiência, divisão muscular, músculos, tags e fallback geral quando necessário.',
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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
          TextField(
            controller: pesoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: alturaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: idadeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Idade'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: tipoFicha,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de ficha'),
            items: tiposFicha.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                tipoFicha = value;
                diasPorSemana = _diasPadraoParaTipo(value);
              });
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: diasPorSemana,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Dias por semana'),
            items: opcoesDiasPorSemana.map((item) {
              return DropdownMenuItem(value: item, child: Text('$item dias'));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                diasPorSemana = value;
              });
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: objetivo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Objetivo'),
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
            initialValue: experiencia,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Experiência'),
            items: experiencias.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                experiencia = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivisaoCard() {
    final ficha = _fichaSelecionada();
    final descricao =
        ficha?.descricao ??
        'Gera um treino avulso com 5 a 8 exercícios escolhidos pelo objetivo e nível.';
    final treinos = ficha?.treinos ?? const <_TreinoFichaConfig>[];

    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipoFicha,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _pill('$diasPorSemana dias'),
            ],
          ),
          if (treinos.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...treinos.map(_divisaoLinha),
          ],
        ],
      ),
    );
  }

  Widget _divisaoLinha(_TreinoFichaConfig config) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.focos.join(' + '),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  int _diasPadraoParaTipo(String tipo) {
    switch (tipo) {
      case _tipoAbcd:
        return 4;
      case _tipoAbcde:
        return 5;
      case _tipoPushPullLegs:
      case _tipoFullBody:
      case _tipoAbc:
      case _tipoTreinoUnico:
      default:
        return 3;
    }
  }
}
