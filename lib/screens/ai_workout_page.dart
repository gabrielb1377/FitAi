import 'package:flutter/material.dart';

import '../design_system/fit_design_system.dart';
import '../models/exercicio_model.dart';
import '../models/treino_model.dart';
import '../services/backend_ai_service.dart';
import '../services/treino_service.dart';
import '../theme/app_theme.dart';
import 'treinos/widgets/plans/plan_wizard_choice_tile.dart';

class AIWorkoutPage extends StatefulWidget {
  const AIWorkoutPage({super.key});

  @override
  State<AIWorkoutPage> createState() => _AIWorkoutPageState();
}

class _AIWorkoutPageState extends State<AIWorkoutPage> {
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  final idadeController = TextEditingController();
  final equipamentosController = TextEditingController();
  final gruposPrioritariosController = TextEditingController();
  final lesoesController = TextEditingController();
  final favoritosController = TextEditingController();
  final evitadosController = TextEditingController();
  final observacoesController = TextEditingController();
  final divisaoPersonalizadaController = TextEditingController();

  final treinoService = TreinoService.instance;
  final backendAIService = BackendAIService();

  String objetivo = 'Hipertrofia';
  String divisao = 'Automática';
  String nivel = 'Iniciante';
  String localTreino = 'Academia';
  int diasPorSemana = 3;
  int tempoPorTreino = 45;
  int minExerciciosPorDia = 6;
  bool carregando = false;

  final objetivos = const [
    'Hipertrofia',
    'Força',
    'Emagrecimento',
    'Resistência',
    'Mobilidade',
  ];

  final divisoes = const [
    'Automática',
    'Full Body',
    'AB',
    'ABC',
    'ABCD',
    'ABCDE',
    'Push/Pull/Legs',
    'Superior/Inferior',
    'Personalizado',
  ];

  final niveis = const ['Iniciante', 'Intermediário', 'Avançado'];
  final locais = const ['Academia', 'Casa', 'Ar livre'];
  final diasOptions = const [2, 3, 4, 5, 6];
  final temposOptions = const [30, 45, 60, 75, 90];
  final minExerciciosOptions = const [6, 7, 8, 9, 10];

  @override
  void dispose() {
    pesoController.dispose();
    alturaController.dispose();
    idadeController.dispose();
    equipamentosController.dispose();
    gruposPrioritariosController.dispose();
    lesoesController.dispose();
    favoritosController.dispose();
    evitadosController.dispose();
    observacoesController.dispose();
    divisaoPersonalizadaController.dispose();
    super.dispose();
  }

  String get divisaoSelecionada {
    if (divisao == 'Automática') return _divisaoRecomendada();
    if (divisao != 'Personalizado') return divisao;
    final personalizada = divisaoPersonalizadaController.text.trim();
    return personalizada.isEmpty ? 'Personalizado' : personalizada;
  }

  Future<void> _gerarTreino() async {
    if (divisao == 'Personalizado' &&
        divisaoPersonalizadaController.text.trim().isEmpty) {
      _snack('Informe a divisão personalizada.');
      return;
    }

    setState(() => carregando = true);

    late final _PlanoGerado plano;

    try {
      final treinoBackend = await backendAIService.generateWorkout(
        objetivo: objetivo,
        divisao: divisaoSelecionada,
        nivel: nivel,
        diasPorSemana: diasPorSemana,
        tempoPorTreino: tempoPorTreino,
        minExerciciosPorDia: _minExerciciosSeguro(),
        local: localTreino,
        equipamentos: _split(equipamentosController.text),
        restricoes: _split(lesoesController.text),
        prioridades: _split(gruposPrioritariosController.text),
        observacoes: observacoesController.text.trim(),
      );

      plano = _planoGeradoFromTreino(treinoBackend);
      _debugLog('Treino gerado pelo backend.');
    } catch (erro) {
      _debugLog('Geracao remota indisponivel. Detalhe: $erro');
      if (mounted) {
        setState(() => carregando = false);
        _snack(
          'Nao foi possivel gerar o plano agora. Verifique a conexao e tente novamente.',
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => carregando = false);

    final confirmado = await _mostrarResumoPlano(plano);

    if (!mounted || confirmado != true) return;

    setState(() => carregando = true);

    try {
      await treinoService.adicionarTreinoComPersistencia(plano.treino);
    } catch (erro) {
      _debugLog('Falha ao persistir plano gerado. Detalhe: $erro');
      if (mounted) {
        setState(() => carregando = false);
        _snack(
          'Nao foi possivel salvar o plano neste dispositivo. Tente novamente.',
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => carregando = false);
    _snack('Treino gerado pela IA FitIA.');
    Navigator.pop(context, true);
  }

  // ignore: unused_element
  _PlanoGerado _montarPlano() {
    final agora = DateTime.now();
    final divisaoFinal = divisaoSelecionada;
    final dias = _montarDias(divisaoFinal);
    final equipamentos = _split(equipamentosController.text);
    final gruposPrioritarios = _split(gruposPrioritariosController.text);
    final lesoes = _split(lesoesController.text);
    final favoritos = _split(favoritosController.text);
    final evitados = _split(evitadosController.text);
    final observacoes = observacoesController.text.trim();

    final todosExercicios = <ExercicioModel>[];
    final planoDias = <TreinoDiaModel>[];

    for (var i = 0; i < dias.length; i++) {
      final dia = dias[i];
      final exercicios = _exerciciosParaDia(
        dia.grupos,
        gruposPrioritarios,
        equipamentos,
        lesoes,
        favoritos,
        evitados,
        i,
        dia,
      );

      todosExercicios.addAll(exercicios);
      planoDias.add(
        TreinoDiaModel(
          codigo: dia.codigo,
          nome: dia.nome,
          ordem: i + 1,
          exercicioIds: exercicios.map((exercicio) => exercicio.id).toList(),
        ),
      );
    }

    final treino = TreinoModel(
      id: 'ia_${agora.microsecondsSinceEpoch}',
      nome: '$divisaoFinal - $objetivo',
      descricao: _descricaoPlano(divisaoFinal, equipamentos, lesoes),
      objetivo: objetivo,
      nivel: nivel,
      divisao: divisaoFinal,
      tempoEstimado: tempoPorTreino,
      diasPorSemana: dias.length,
      local: localTreino,
      equipamentos: equipamentos,
      gruposPrioritarios: gruposPrioritarios,
      lesoesRestricoes: lesoes,
      exerciciosFavoritos: favoritos,
      exerciciosEvitados: evitados,
      observacoes: observacoes,
      criadoPorIA: true,
      exercicios: todosExercicios,
      planoDias: planoDias,
      dataCriacao: agora.toIso8601String(),
    );

    return _PlanoGerado(
      treino: treino,
      dias: dias,
      totalExercicios: todosExercicios.length,
      volumeSemanal: _volumeSemanalEstimado(todosExercicios.length),
      tempoTotal: tempoPorTreino * dias.length,
    );
  }

  _PlanoGerado _planoGeradoFromTreino(TreinoModel treino) {
    final dias = treino.planoDias.isEmpty
        ? [
            _DiaPlano(
              'Dia 1',
              treino.nome,
              treino.exercicios
                  .map((exercicio) => exercicio.categoria)
                  .toSet()
                  .toList(),
            ),
          ]
        : treino.planoDias.map((dia) {
            return _DiaPlano(dia.codigo, dia.nome, _gruposFromTitulo(dia.nome));
          }).toList();
    final diasCount = dias.isEmpty ? 1 : dias.length;

    return _PlanoGerado(
      treino: treino,
      dias: dias,
      totalExercicios: treino.exercicios.length,
      volumeSemanal: _volumeSemanalEstimado(treino.exercicios.length),
      tempoTotal: treino.tempoEstimado * diasCount,
    );
  }

  List<_DiaPlano> _montarDias(String divisaoTreino) {
    return _prepararDias(_montarDiasBase(divisaoTreino));
  }

  List<_DiaPlano> _montarDiasBase(String divisaoTreino) {
    final normalizada = divisaoTreino.toLowerCase();

    if (divisao == 'Personalizado') {
      final personalizados = _parseDivisaoPersonalizada(divisaoTreino);
      if (personalizados.isNotEmpty) return _expandirDias(personalizados);
    }

    if (normalizada == 'ab') {
      return _expandirDias(const [
        _DiaPlano('A', 'Superior', ['Peito', 'Costas', 'Ombros', 'Braços']),
        _DiaPlano('B', 'Inferior', ['Pernas', 'Glúteos', 'Abdômen']),
      ]);
    }

    if (normalizada == 'abc') {
      return _expandirDias(const [
        _DiaPlano('A', 'Peito + Tríceps', ['Peito', 'Tríceps']),
        _DiaPlano('B', 'Costas + Bíceps', ['Costas', 'Bíceps']),
        _DiaPlano('C', 'Pernas + Abdômen', ['Pernas', 'Glúteos', 'Abdômen']),
      ]);
    }

    if (normalizada == 'abcd') {
      return _expandirDias(const [
        _DiaPlano('A', 'Peito', ['Peito']),
        _DiaPlano('B', 'Costas', ['Costas']),
        _DiaPlano('C', 'Pernas + Glúteos', ['Pernas', 'Glúteos']),
        _DiaPlano('D', 'Ombros + Braços', ['Ombros', 'Bíceps', 'Tríceps']),
      ]);
    }

    if (normalizada == 'abcde') {
      return _expandirDias(const [
        _DiaPlano('A', 'Peito', ['Peito']),
        _DiaPlano('B', 'Costas', ['Costas']),
        _DiaPlano('C', 'Pernas', ['Pernas']),
        _DiaPlano('D', 'Ombros', ['Ombros']),
        _DiaPlano('E', 'Braços', ['Bíceps', 'Tríceps']),
      ]);
    }

    if (normalizada.contains('push')) {
      if (normalizada.contains('upper')) {
        return _expandirDias(const [
          _DiaPlano('Push', 'Peito + Ombros + Tríceps', [
            'Peito',
            'Ombros',
            'Tríceps',
          ]),
          _DiaPlano('Pull', 'Costas + Bíceps', ['Costas', 'Bíceps']),
          _DiaPlano('Legs', 'Pernas + Glúteos', ['Pernas', 'Glúteos']),
          _DiaPlano('Upper', 'Superior completo', [
            'Peito',
            'Costas',
            'Ombros',
            'Braços',
          ]),
          _DiaPlano('Core', 'Core + Condicionamento', ['Abdômen', 'Cardio']),
        ]);
      }

      return _expandirDias(const [
        _DiaPlano('Push', 'Peito + Ombros + Tríceps', [
          'Peito',
          'Ombros',
          'Tríceps',
        ]),
        _DiaPlano('Pull', 'Costas + Bíceps', ['Costas', 'Bíceps']),
        _DiaPlano('Legs', 'Pernas + Glúteos', ['Pernas', 'Glúteos']),
      ]);
    }

    if (normalizada.contains('superior')) {
      return _expandirDias(const [
        _DiaPlano('Superior', 'Superior', [
          'Peito',
          'Costas',
          'Ombros',
          'Braços',
        ]),
        _DiaPlano('Inferior', 'Inferior', ['Pernas', 'Glúteos', 'Abdômen']),
      ]);
    }

    return List.generate(diasPorSemana, (index) {
      final nome = objetivo == 'Mobilidade' ? 'Mobilidade' : 'Full Body';
      return _DiaPlano('Dia ${index + 1}', nome, [
        'Peito',
        'Costas',
        'Pernas',
        'Ombros',
        'Abdômen',
      ]);
    });
  }

  String _divisaoRecomendada() {
    final objetivoNormalizado = _normalizar(objetivo);

    switch (diasPorSemana) {
      case 2:
        return objetivoNormalizado.contains('mobilidade') ||
                objetivoNormalizado.contains('resistencia')
            ? 'Full Body'
            : 'Superior/Inferior';
      case 3:
        return objetivoNormalizado.contains('mobilidade') ||
                objetivoNormalizado.contains('emagrec')
            ? 'Full Body'
            : 'ABC';
      case 4:
        return objetivoNormalizado.contains('mobilidade')
            ? 'Superior/Inferior'
            : 'ABCD';
      case 5:
        return objetivoNormalizado.contains('forca') ||
                objetivoNormalizado.contains('hipertrofia')
            ? 'ABCDE'
            : 'Push/Pull/Legs + Upper';
      case 6:
        return 'Push/Pull/Legs x2';
      default:
        return 'Full Body';
    }
  }

  List<_DiaPlano> _prepararDias(List<_DiaPlano> dias) {
    final comPrioridade = _aplicarPrioridadeMuscular(dias);
    return _evitarMusculosConsecutivos(comPrioridade);
  }

  List<_DiaPlano> _aplicarPrioridadeMuscular(List<_DiaPlano> dias) {
    final prioridades = _split(gruposPrioritariosController.text);
    if (prioridades.isEmpty) return dias;

    return List.generate(dias.length, (index) {
      final dia = dias[index];
      if (index >= prioridades.length) return dia;

      final prioridade = prioridades[index];
      final jaExiste = dia.grupos.any(
        (grupo) => _normalizar(grupo) == _normalizar(prioridade),
      );

      if (jaExiste) return dia;

      return _DiaPlano(dia.codigo, '${dia.nome} + $prioridade', [
        prioridade,
        ...dia.grupos,
      ]);
    });
  }

  List<_DiaPlano> _evitarMusculosConsecutivos(List<_DiaPlano> dias) {
    final ajustados = List<_DiaPlano>.from(dias);

    for (var index = 1; index < ajustados.length; index++) {
      if (!_temSobreposicao(ajustados[index - 1], ajustados[index])) continue;

      for (
        var candidato = index + 1;
        candidato < ajustados.length;
        candidato++
      ) {
        if (!_temSobreposicao(ajustados[index - 1], ajustados[candidato])) {
          final atual = ajustados[index];
          ajustados[index] = ajustados[candidato];
          ajustados[candidato] = atual;
          break;
        }
      }
    }

    return ajustados;
  }

  bool _temSobreposicao(_DiaPlano anterior, _DiaPlano atual) {
    final gruposAnteriores = anterior.grupos.map(_normalizar).toSet();

    return atual.grupos.map(_normalizar).any(gruposAnteriores.contains);
  }

  List<_DiaPlano> _expandirDias(List<_DiaPlano> base) {
    return List.generate(diasPorSemana, (index) {
      final dia = base[index % base.length];
      final repeticao = index ~/ base.length;
      final codigo = repeticao == 0
          ? dia.codigo
          : '${dia.codigo}${repeticao + 1}';

      return _DiaPlano(codigo, dia.nome, dia.grupos);
    });
  }

  List<_DiaPlano> _parseDivisaoPersonalizada(String texto) {
    return texto
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) {
          final partes = item.split(RegExp(r'\s+'));
          final codigo = partes.length > 1 ? partes.first : '';
          final nome = partes.length > 1
              ? partes.skip(1).join(' ')
              : item.replaceAll('-', '').trim();
          final grupos = nome
              .split(RegExp(r'\+|/| e '))
              .map((grupo) => grupo.trim())
              .where((grupo) => grupo.isNotEmpty)
              .toList();

          return _DiaPlano(codigo, nome.isEmpty ? item : nome, grupos);
        })
        .toList();
  }

  List<ExercicioModel> _exerciciosParaDia(
    List<String> grupos,
    List<String> gruposPrioritarios,
    List<String> equipamentos,
    List<String> lesoes,
    List<String> favoritos,
    List<String> evitados,
    int diaIndex,
    _DiaPlano dia,
  ) {
    final alvo = _alvoExerciciosPorDia(dia.grupos);
    final gruposDoDia = <String>[
      ...grupos,
      if (objetivo == 'Emagrecimento') ...['Cardio', 'Funcional'],
      if (objetivo == 'Mobilidade') ...['Mobilidade', 'Core'],
    ];
    final seeds = <_ExercicioSeed>[
      ...favoritos.map(
        (nome) => _ExercicioSeed(
          nome,
          gruposDoDia.isEmpty ? 'Full Body' : gruposDoDia.first,
          ['Corpo inteiro'],
          const [],
          const ['Casa', 'Academia', 'Ar livre'],
          300,
        ),
      ),
      for (final grupo in gruposDoDia) ..._templatesPorGrupo(grupo),
    ];

    var filtrados = _deduplicar(seeds).where((seed) {
      return !_contemAlgum(seed.nome, evitados) &&
          !_contemAlgum(seed.nome, lesoes) &&
          !_contemAlgum(seed.categoria, lesoes);
    }).toList();

    final porLocal = filtrados.where((seed) {
      return seed.locais.any(
        (local) => _normalizar(local) == _normalizar(localTreino),
      );
    }).toList();
    if (porLocal.isNotEmpty) filtrados = porLocal;

    if (equipamentos.isNotEmpty) {
      final porEquipamento = filtrados.where((seed) {
        return seed.equipamentos.isEmpty ||
            seed.equipamentos.any(
              (equipamento) => _contemAlgum(equipamento, equipamentos),
            );
      }).toList();
      if (porEquipamento.isNotEmpty) filtrados = porEquipamento;
    }

    if (filtrados.length < alvo) {
      filtrados =
          _deduplicar([
            ...filtrados,
            for (final grupo in gruposDoDia) ..._templatesPorGrupo(grupo),
            ..._templatesPorGrupo('Full Body'),
            ..._templatesPorGrupo('Peito'),
            ..._templatesPorGrupo('Costas'),
            ..._templatesPorGrupo('Pernas'),
            ..._templatesPorGrupo('Ombros'),
            ..._templatesPorGrupo('Bracos'),
            ..._templatesPorGrupo('Abdomen'),
            ..._templatesPorGrupo('Cardio'),
            ..._templatesPorGrupo('Mobilidade'),
          ]).where((seed) {
            return !_contemAlgum(seed.nome, evitados) &&
                !_contemAlgum(seed.nome, lesoes) &&
                !_contemAlgum(seed.categoria, lesoes);
          }).toList();
    }

    final variados = _rotacionarExercicios(filtrados, diaIndex);

    return variados.take(alvo).map((seed) {
      return _exercicio(seed, diaIndex, dia);
    }).toList();
  }

  int _alvoExerciciosPorDia(List<String> grupos) {
    var alvo = (tempoPorTreino / 9).round().clamp(4, 10).toInt();
    final objetivoNormalizado = _normalizar(objetivo);
    final minimo = _minExerciciosSeguro();

    if (objetivoNormalizado.contains('forca')) {
      alvo = alvo.clamp(4, 10).toInt();
    } else if (objetivoNormalizado.contains('mobilidade')) {
      alvo = alvo.clamp(3, 10).toInt();
    } else if (diasPorSemana >= 5) {
      alvo = alvo.clamp(4, 10).toInt();
    }

    if (grupos.length >= 3 && tempoPorTreino >= 60) {
      alvo = (alvo + 1).clamp(4, 10).toInt();
    }

    if (alvo < minimo) {
      alvo = minimo;
    }

    return alvo;
  }

  List<_ExercicioSeed> _rotacionarExercicios(
    List<_ExercicioSeed> seeds,
    int diaIndex,
  ) {
    if (seeds.length < 2) return seeds;

    final offset = diaIndex % seeds.length;
    return [...seeds.skip(offset), ...seeds.take(offset)];
  }

  List<_ExercicioSeed> _templatesPorGrupo(String grupo) {
    final valor = _normalizar(grupo);

    if (valor.contains('peito')) {
      return const [
        _ExercicioSeed(
          'Supino Reto',
          'Peito',
          ['Peitoral', 'Tríceps'],
          ['Barra', 'Banco'],
          ['Academia'],
          400,
        ),
        _ExercicioSeed(
          'Flexão de Braços',
          'Peito',
          ['Peitoral', 'Tríceps'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          320,
        ),
        _ExercicioSeed(
          'Crucifixo com Halteres',
          'Peito',
          ['Peitoral'],
          ['Halteres', 'Banco'],
          ['Casa', 'Academia'],
          330,
        ),
      ];
    }

    if (valor.contains('costa')) {
      return const [
        _ExercicioSeed(
          'Puxada Frontal',
          'Costas',
          ['Costas', 'Bíceps'],
          ['Polia'],
          ['Academia'],
          350,
        ),
        _ExercicioSeed(
          'Remada Curvada',
          'Costas',
          ['Costas', 'Bíceps'],
          ['Barra'],
          ['Academia'],
          420,
        ),
        _ExercicioSeed(
          'Remada Unilateral',
          'Costas',
          ['Costas'],
          ['Halteres'],
          ['Casa', 'Academia'],
          360,
        ),
      ];
    }

    if (valor.contains('perna') || valor.contains('glute')) {
      return const [
        _ExercicioSeed(
          'Agachamento Livre',
          'Pernas',
          ['Quadríceps', 'Glúteos'],
          ['Barra'],
          ['Academia'],
          500,
        ),
        _ExercicioSeed(
          'Afundo Alternado',
          'Pernas',
          ['Quadríceps', 'Glúteos'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          360,
        ),
        _ExercicioSeed(
          'Leg Press',
          'Pernas',
          ['Quadríceps', 'Glúteos'],
          ['Máquina'],
          ['Academia'],
          460,
        ),
      ];
    }

    if (valor.contains('ombro')) {
      return const [
        _ExercicioSeed(
          'Desenvolvimento com Halteres',
          'Ombros',
          ['Ombros', 'Tríceps'],
          ['Halteres'],
          ['Casa', 'Academia'],
          340,
        ),
        _ExercicioSeed('Elevação Lateral', 'Ombros', ['Ombros'], ['Halteres'], [
          'Casa',
          'Academia',
        ], 260),
      ];
    }

    if (valor.contains('bicep') ||
        valor.contains('tricep') ||
        valor.contains('braco')) {
      return const [
        _ExercicioSeed('Rosca Direta', 'Bíceps', ['Bíceps'], ['Barra'], [
          'Academia',
        ], 260),
        _ExercicioSeed('Rosca Alternada', 'Bíceps', ['Bíceps'], ['Halteres'], [
          'Casa',
          'Academia',
        ], 250),
        _ExercicioSeed('Tríceps Corda', 'Tríceps', ['Tríceps'], ['Polia'], [
          'Academia',
        ], 260),
        _ExercicioSeed(
          'Mergulho no Banco',
          'Tríceps',
          ['Tríceps', 'Peitoral'],
          [],
          ['Casa', 'Academia'],
          300,
        ),
      ];
    }

    if (valor.contains('abd') || valor.contains('core')) {
      return const [
        _ExercicioSeed(
          'Prancha',
          'Abdômen',
          ['Core'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          250,
        ),
        _ExercicioSeed(
          'Abdominal Infra',
          'Abdômen',
          ['Abdômen'],
          [],
          ['Casa', 'Academia'],
          220,
        ),
      ];
    }

    if (valor.contains('cardio') || valor.contains('funcional')) {
      return const [
        _ExercicioSeed(
          'Corrida Leve',
          'Cardio',
          ['Corpo inteiro'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          650,
        ),
        _ExercicioSeed(
          'Burpee',
          'Funcional',
          ['Corpo inteiro'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          600,
        ),
        _ExercicioSeed(
          'Polichinelo',
          'Cardio',
          ['Corpo inteiro'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          450,
        ),
      ];
    }

    if (valor.contains('mobilidade')) {
      return const [
        _ExercicioSeed(
          'Mobilidade de Quadril',
          'Mobilidade',
          ['Quadril'],
          [],
          ['Casa', 'Academia', 'Ar livre'],
          160,
        ),
        _ExercicioSeed(
          'Alongamento Torácico',
          'Mobilidade',
          ['Coluna', 'Ombros'],
          [],
          ['Casa', 'Academia'],
          140,
        ),
        _ExercicioSeed(
          'Liberação de Posterior',
          'Mobilidade',
          ['Posterior de Coxa'],
          [],
          ['Casa', 'Academia'],
          150,
        ),
      ];
    }

    return const [
      _ExercicioSeed(
        'Agachamento Livre',
        'Pernas',
        ['Quadríceps', 'Glúteos'],
        [],
        ['Casa', 'Academia', 'Ar livre'],
        300,
      ),
      _ExercicioSeed(
        'Flexão de Braços',
        'Peito',
        ['Peitoral', 'Tríceps'],
        [],
        ['Casa', 'Academia', 'Ar livre'],
        320,
      ),
      _ExercicioSeed(
        'Prancha',
        'Abdômen',
        ['Core'],
        [],
        ['Casa', 'Academia', 'Ar livre'],
        250,
      ),
      _ExercicioSeed('Remada Unilateral', 'Costas', ['Costas'], ['Halteres'], [
        'Casa',
        'Academia',
      ], 360),
    ];
  }

  ExercicioModel _exercicio(_ExercicioSeed seed, int diaIndex, _DiaPlano dia) {
    return ExercicioModel(
      id: 'ia_${_normalizar(seed.nome)}_${DateTime.now().microsecondsSinceEpoch}_${diaIndex}_${_normalizar(dia.codigo)}',
      nome: seed.nome,
      categoria: seed.categoria,
      descricao:
          'Exercício selecionado para $objetivo, nível $nivel, em $localTreino.',
      comoExecutar:
          'Execute com controle, postura estável e amplitude segura para o seu nível.',
      cuidados:
          'Respeite as restrições informadas e reduza a intensidade em caso de dor.',
      musculos: seed.musculos,
      equipamentos: seed.equipamentos,
      locais: seed.locais,
      dificuldade: nivel,
      objetivo: objetivo,
      imagem: '',
      video: '',
      tags: [
        objetivo.toLowerCase(),
        seed.categoria.toLowerCase(),
        localTreino.toLowerCase(),
        'dia:${dia.codigo}',
        'divisao:${dia.nome}',
        ...seed.musculos.map((item) => item.toLowerCase()),
      ],
      caloriasHora: seed.caloriasHora,
    );
  }

  List<_ExercicioSeed> _deduplicar(List<_ExercicioSeed> seeds) {
    final nomes = <String>{};
    final resultado = <_ExercicioSeed>[];

    for (final seed in seeds) {
      final chave = _normalizar(seed.nome);
      if (nomes.add(chave)) resultado.add(seed);
    }

    return resultado;
  }

  String _descricaoPlano(
    String dia,
    List<String> equipamentos,
    List<String> lesoes,
  ) {
    final partes = [
      'Plano $divisaoSelecionada para $objetivo.',
      'Dia: $dia.',
      'Local: $localTreino.',
      'Nível: $nivel.',
      if (equipamentos.isNotEmpty) 'Equipamentos: ${equipamentos.join(", ")}.',
      if (lesoes.isNotEmpty) 'Restrições consideradas: ${lesoes.join(", ")}.',
      if (observacoesController.text.trim().isNotEmpty)
        'Observações: ${observacoesController.text.trim()}',
    ];

    return partes.join(' ');
  }

  int _seriesPorExercicio() {
    final objetivoNormalizado = _normalizar(objetivo);
    final nivelNormalizado = _normalizar(nivel);

    if (objetivoNormalizado.contains('mobilidade')) return 2;
    if (objetivoNormalizado.contains('forca')) return 5;
    if (nivelNormalizado.contains('avancado')) return 4;

    return 3;
  }

  String _volumeSemanalEstimado(int totalExercicios) {
    final series = totalExercicios * _seriesPorExercicio();
    final intensidade = _normalizar(objetivo).contains('forca')
        ? 'alta'
        : _normalizar(objetivo).contains('mobilidade')
        ? 'leve'
        : 'moderada';

    return '$series séries/$intensidade';
  }

  Future<bool?> _mostrarResumoPlano(_PlanoGerado plano) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Resumo do plano'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResumoLinha(
                  label: 'Plano escolhido',
                  value: plano.treino.nome,
                  icon: Icons.auto_awesome_rounded,
                ),
                _ResumoLinha(
                  label: 'Divisão',
                  value: plano.treino.divisao,
                  icon: Icons.account_tree_rounded,
                ),
                _ResumoLinha(
                  label: 'Dias',
                  value: '${plano.dias.length} por semana',
                  icon: Icons.calendar_month_rounded,
                ),
                _ResumoLinha(
                  label: 'Exercícios',
                  value: '${plano.totalExercicios}',
                  icon: Icons.fitness_center_rounded,
                ),
                _ResumoLinha(
                  label: 'Minimo por dia',
                  value: '${_minExerciciosSeguro()} exercicios',
                  icon: Icons.format_list_numbered_rounded,
                ),
                _ResumoLinha(
                  label: 'Tempo estimado',
                  value: '${plano.tempoTotal} min/semana',
                  icon: Icons.timer_rounded,
                ),
                _ResumoLinha(
                  label: 'Volume semanal',
                  value: plano.volumeSemanal,
                  icon: Icons.monitor_weight_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribuição',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final dia in plano.dias)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            '${dia.codigo} - ${dia.nome}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ajustar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar plano'),
            ),
          ],
        );
      },
    );
  }

  int _minExerciciosSeguro() {
    return minExerciciosOptions.contains(minExerciciosPorDia)
        ? minExerciciosPorDia
        : 6;
  }

  List<String> _split(String value) {
    return value
        .split(RegExp(r',|;|\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _gruposFromTitulo(String value) {
    final grupos = value
        .split(RegExp(r'\+|/| e '))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return grupos.isEmpty ? [value] : grupos;
  }

  bool _contemAlgum(String texto, List<String> termos) {
    final normalizado = _normalizar(texto);

    return termos.any((termo) => normalizado.contains(_normalizar(termo)));
  }

  String _normalizar(String value) {
    var texto = value.toLowerCase().trim();
    const substituicoes = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };

    for (final item in substituicoes.entries) {
      texto = texto.replaceAll(item.key, item.value);
    }

    return texto;
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint('[AIWorkoutPage] $message');
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                FitHeader(
                  title: 'Criar plano IA',
                  showBackButton: true,
                  onBack: () => Navigator.maybePop(context),
                  trailing: const FitBadge.ai(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: FitSpacing.s20),
                  child: FitProgress(value: 0.2),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      FitSpacing.s20,
                      FitSpacing.s24,
                      FitSpacing.s20,
                      FitSpacing.s24,
                    ),
                    children: [
                      Text(
                        'Vamos criar o seu plano',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: FitSpacing.s8),
                      Text(
                        'A IA usa suas escolhas para montar uma rotina unica e adaptada ao seu momento.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: FitSpacing.s24),
                      PlanWizardChoiceTile(
                        index: 1,
                        label: 'Objetivo principal',
                        value: objetivo,
                        onTap: () => _selectString(
                          title: 'Objetivo principal',
                          options: objetivos,
                          selected: objetivo,
                          onSelected: (value) => objetivo = value,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      PlanWizardChoiceTile(
                        index: 2,
                        label: 'Experiencia de treino',
                        value: nivel,
                        onTap: () => _selectString(
                          title: 'Experiencia de treino',
                          options: niveis,
                          selected: nivel,
                          onSelected: (value) => nivel = value,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      PlanWizardChoiceTile(
                        index: 3,
                        label: 'Frequencia semanal',
                        value: '$diasPorSemana dias por semana',
                        onTap: () => _selectInt(
                          title: 'Frequencia semanal',
                          options: diasOptions,
                          selected: diasPorSemana,
                          suffix: 'dias por semana',
                          onSelected: (value) => diasPorSemana = value,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      PlanWizardChoiceTile(
                        index: 4,
                        label: 'Duracao do treino',
                        value: '$tempoPorTreino minutos',
                        onTap: () => _selectInt(
                          title: 'Duracao do treino',
                          options: temposOptions,
                          selected: tempoPorTreino,
                          suffix: 'minutos',
                          onSelected: (value) => tempoPorTreino = value,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      PlanWizardChoiceTile(
                        index: 5,
                        label: 'Equipamentos disponiveis',
                        value: _equipmentSummary,
                        onTap: _showAdvancedPreferences,
                      ),
                      const SizedBox(height: FitSpacing.s16),
                      FitButton(
                        label: 'Preferencias avancadas',
                        leadingIcon: Icons.tune_rounded,
                        variant: FitButtonVariant.ghost,
                        onPressed: _showAdvancedPreferences,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          FitSpacing.s20,
          FitSpacing.s8,
          FitSpacing.s20,
          FitSpacing.s16,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FitButton(
              label: carregando ? 'Gerando plano...' : 'Gerar plano com IA',
              leadingIcon: Icons.auto_awesome_rounded,
              onPressed: carregando ? null : _gerarTreino,
              isLoading: carregando,
              expand: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectString({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final value = await FitBottomSheet.show<String>(
      context: context,
      title: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 52,
              title: Text(option),
              trailing: option == selected
                  ? const Icon(Icons.check_rounded, color: FitColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, option),
            );
          },
        ),
      ),
    );
    if (!mounted || value == null) return;
    setState(() => onSelected(value));
  }

  Future<void> _selectInt({
    required String title,
    required List<int> options,
    required int selected,
    required String suffix,
    required ValueChanged<int> onSelected,
  }) async {
    final value = await FitBottomSheet.show<int>(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map((option) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 52,
                title: Text('$option $suffix'),
                trailing: option == selected
                    ? const Icon(Icons.check_rounded, color: FitColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, option),
              );
            })
            .toList(growable: false),
      ),
    );
    if (!mounted || value == null) return;
    setState(() => onSelected(value));
  }

  Future<void> _showAdvancedPreferences() async {
    await FitBottomSheet.show<void>(
      context: context,
      title: 'Preferencias avancadas',
      subtitle: 'Contexto opcional para deixar a geracao mais precisa.',
      isScrollControlled: true,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildDadosPessoais(),
            const SizedBox(height: FitSpacing.s16),
            _buildConfiguracaoTreino(),
            const SizedBox(height: FitSpacing.s16),
            _buildPreferencias(),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  String get _equipmentSummary {
    final value = equipamentosController.text.trim();
    if (value.isNotEmpty) return value;
    return localTreino == 'Academia' ? 'Academia completa' : localTreino;
  }

  // Mantido apenas como referencia durante a migracao incremental da UI.
  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Gerador de Treino IA')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          AppGradientCard(
            gradient: AppColors.gradientPrimary,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 30),
                SizedBox(height: 14),
                Text(
                  'Ficha inteligente',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Configure objetivo, divisão, dias, local e restrições. A IA local salva um plano único com dias internos.',
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildDadosPessoais(),
          const SizedBox(height: 18),
          _buildConfiguracaoTreino(),
          const SizedBox(height: 18),
          _buildPreferencias(),
          const SizedBox(height: 26),
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
              carregando ? 'Gerando plano...' : 'Gerar Plano Inteligente',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDadosPessoais() {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dados básicos'),
          const SizedBox(height: 12),
          _textField(pesoController, 'Peso (kg)', TextInputType.number),
          const SizedBox(height: 12),
          _textField(alturaController, 'Altura (cm)', TextInputType.number),
          const SizedBox(height: 12),
          _textField(idadeController, 'Idade', TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildConfiguracaoTreino() {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Plano'),
          const SizedBox(height: 12),
          _dropdown('Objetivo', objetivo, objetivos, (value) {
            setState(() => objetivo = value);
          }),
          const SizedBox(height: 12),
          _dropdown('Divisão', divisao, divisoes, (value) {
            setState(() => divisao = value);
          }),
          if (divisao == 'Personalizado') ...[
            const SizedBox(height: 12),
            _textField(
              divisaoPersonalizadaController,
              'Divisão personalizada',
              TextInputType.text,
              hint: 'Ex: A Peito, B Costas, C Pernas',
            ),
          ],
          const SizedBox(height: 12),
          _dropdown('Nível', nivel, niveis, (value) {
            setState(() => nivel = value);
          }),
          const SizedBox(height: 12),
          _dropdown('Local', localTreino, locais, (value) {
            setState(() => localTreino = value);
          }),
          const SizedBox(height: 12),
          _intDropdown('Dias por semana', diasPorSemana, diasOptions, (value) {
            setState(() => diasPorSemana = value);
          }),
          const SizedBox(height: 12),
          _intDropdown('Tempo por treino', tempoPorTreino, temposOptions, (
            value,
          ) {
            setState(() => tempoPorTreino = value);
          }, suffix: 'min'),
          const SizedBox(height: 12),
          _buildMinExerciciosSelector(),
          const SizedBox(height: 12),
          _buildResumoSolicitacao(),
        ],
      ),
    );
  }

  Widget _buildPreferencias() {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Preferências'),
          const SizedBox(height: 12),
          _textField(
            equipamentosController,
            'Equipamentos',
            TextInputType.text,
            hint: 'Ex: barra, halteres, polia',
          ),
          const SizedBox(height: 12),
          _textField(
            gruposPrioritariosController,
            'Grupos prioritários',
            TextInputType.text,
            hint: 'Ex: peito, costas, pernas',
          ),
          const SizedBox(height: 12),
          _textField(
            lesoesController,
            'Lesões/restrições',
            TextInputType.text,
            hint: 'Ex: joelho, ombro, lombar',
          ),
          const SizedBox(height: 12),
          _textField(
            favoritosController,
            'Exercícios favoritos',
            TextInputType.text,
            hint: 'Ex: supino reto, agachamento',
          ),
          const SizedBox(height: 12),
          _textField(
            evitadosController,
            'Exercícios evitados',
            TextInputType.text,
            hint: 'Ex: burpee, leg press',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: observacoesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Observações'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildMinExerciciosSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantidade minima de exercicios por dia',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: minExerciciosOptions.map((value) {
            final selected = value == _minExerciciosSeguro();

            return ChoiceChip(
              label: Text('$value exercicios'),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: selected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
              onSelected: (_) {
                setState(() => minExerciciosPorDia = value);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResumoSolicitacao() {
    final divisaoFinal = divisaoSelecionada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo antes de gerar',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$diasPorSemana dias por semana, $tempoPorTreino min por treino, minimo de ${_minExerciciosSeguro()} exercicios por dia, divisao $divisaoFinal.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    TextInputType keyboardType, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }

  Widget _intDropdown(
    String label,
    int value,
    List<int> items,
    ValueChanged<int> onChanged, {
    String suffix = '',
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        final label = suffix.isEmpty ? '$item' : '$item $suffix';
        return DropdownMenuItem(value: item, child: Text(label));
      }).toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _DiaPlano {
  final String codigo;
  final String nome;
  final List<String> grupos;

  const _DiaPlano(this.codigo, this.nome, this.grupos);
}

class _ExercicioSeed {
  final String nome;
  final String categoria;
  final List<String> musculos;
  final List<String> equipamentos;
  final List<String> locais;
  final int caloriasHora;

  const _ExercicioSeed(
    this.nome,
    this.categoria,
    this.musculos,
    this.equipamentos,
    this.locais,
    this.caloriasHora,
  );
}

class _PlanoGerado {
  final TreinoModel treino;
  final List<_DiaPlano> dias;
  final int totalExercicios;
  final String volumeSemanal;
  final int tempoTotal;

  const _PlanoGerado({
    required this.treino,
    required this.dias,
    required this.totalExercicios,
    required this.volumeSemanal,
    required this.tempoTotal,
  });
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResumoLinha({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
