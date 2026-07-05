import 'package:flutter/material.dart';

import '../models/exercicio_model.dart';
import '../models/treino_model.dart';
import '../services/treino_service.dart';
import '../theme/app_theme.dart';

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

  String objetivo = 'Hipertrofia';
  String divisao = 'Full Body';
  String nivel = 'Iniciante';
  String localTreino = 'Academia';
  int diasPorSemana = 3;
  int tempoPorTreino = 45;
  bool carregando = false;

  final objetivos = const [
    'Hipertrofia',
    'Força',
    'Emagrecimento',
    'Resistência',
    'Mobilidade',
  ];

  final divisoes = const [
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

    final dias = _montarDias(divisaoSelecionada);
    final agora = DateTime.now();
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
      nome: '$divisaoSelecionada - $objetivo',
      descricao: _descricaoPlano(divisaoSelecionada, equipamentos, lesoes),
      objetivo: objetivo,
      nivel: nivel,
      divisao: divisaoSelecionada,
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

    treinoService.adicionarTreino(treino);

    if (!mounted) return;

    setState(() => carregando = false);
    _snack('Ficha $divisaoSelecionada gerada com ${dias.length} dias.');
    Navigator.pop(context, true);
  }

  List<_DiaPlano> _montarDias(String divisaoTreino) {
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
    final alvo = (tempoPorTreino / 9).round().clamp(4, 8);
    final gruposDoDia = <String>[
      ...gruposPrioritarios,
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
      filtrados = _deduplicar([
        ...filtrados,
        ..._templatesPorGrupo('Full Body'),
        ..._templatesPorGrupo('Mobilidade'),
      ]);
    }

    return filtrados.take(alvo).map((seed) {
      return _exercicio(seed, diaIndex, dia);
    }).toList();
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

  List<String> _split(String value) {
    return value
        .split(RegExp(r',|;|\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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

  @override
  Widget build(BuildContext context) {
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
