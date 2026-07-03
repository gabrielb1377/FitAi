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
  final divisaoPersonalizadaController = TextEditingController();
  final treinoService = TreinoService.instance;

  String experiencia = 'Iniciante';
  String objetivo = 'Hipertrofia';
  String divisao = 'Full Body';
  bool carregando = false;

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

  @override
  void dispose() {
    pesoController.dispose();
    alturaController.dispose();
    idadeController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a divisao personalizada.')),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    final divisaoTreino = divisaoSelecionada;
    final exercicios = _exerciciosPorObjetivo(objetivo, divisaoTreino);

    final treino = TreinoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: '$divisaoTreino - $objetivo',
      descricao:
          'Treino $divisaoTreino gerado pela IA com base no objetivo $objetivo e nível $experiencia.',
      objetivo: objetivo,
      nivel: experiencia,
      divisao: divisaoTreino,
      tempoEstimado: exercicios.length * 8,
      criadoPorIA: true,
      exercicios: exercicios,
      dataCriacao: DateTime.now().toIso8601String(),
    );

    treinoService.adicionarTreino(treino);

    if (!mounted) return;

    setState(() {
      carregando = false;
    });

    Navigator.pop(context, true);
  }

  List<ExercicioModel> _exerciciosPorObjetivo(
    String objetivo,
    String divisaoTreino,
  ) {
    final divisaoNormalizada = divisaoTreino.toLowerCase();

    if (divisaoNormalizada.contains('push')) {
      return [
        _exercicio(
          id: 'ia_push_001',
          nome: 'Supino Reto',
          categoria: 'Peito',
          musculos: ['Peitoral', 'Tríceps'],
          equipamentos: ['Barra', 'Banco'],
          locais: ['Academia'],
          caloriasHora: 400,
        ),
        _exercicio(
          id: 'ia_pull_001',
          nome: 'Puxada Frontal',
          categoria: 'Costas',
          musculos: ['Costas', 'Bíceps'],
          equipamentos: ['Polia'],
          locais: ['Academia'],
          caloriasHora: 350,
        ),
        _exercicio(
          id: 'ia_legs_001',
          nome: 'Agachamento Livre',
          categoria: 'Perna',
          musculos: ['Quadríceps', 'Glúteos'],
          equipamentos: ['Barra'],
          locais: ['Academia'],
          caloriasHora: 500,
        ),
      ];
    }

    if (divisaoNormalizada == 'ab' || divisaoNormalizada.contains('superior')) {
      return [
        _exercicio(
          id: 'ia_sup_001',
          nome: 'Supino Reto',
          categoria: 'Peito',
          musculos: ['Peitoral', 'Tríceps'],
          equipamentos: ['Barra', 'Banco'],
          locais: ['Academia'],
          caloriasHora: 400,
        ),
        _exercicio(
          id: 'ia_sup_002',
          nome: 'Remada Curvada',
          categoria: 'Costas',
          musculos: ['Costas', 'Bíceps'],
          equipamentos: ['Barra'],
          locais: ['Academia'],
          caloriasHora: 420,
        ),
        _exercicio(
          id: 'ia_inf_001',
          nome: 'Agachamento Livre',
          categoria: 'Perna',
          musculos: ['Quadríceps', 'Glúteos'],
          equipamentos: ['Barra'],
          locais: ['Academia'],
          caloriasHora: 500,
        ),
      ];
    }

    if (objetivo == 'Emagrecimento') {
      return [
        _exercicio(
          id: 'ia_cardio_001',
          nome: 'Corrida Leve',
          categoria: 'Cardio',
          musculos: ['Corpo Inteiro'],
          equipamentos: [],
          locais: ['Casa', 'Academia', 'Rua'],
          caloriasHora: 650,
        ),
        _exercicio(
          id: 'ia_func_001',
          nome: 'Burpee',
          categoria: 'Funcional',
          musculos: ['Corpo Inteiro'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 600,
        ),
        _exercicio(
          id: 'ia_abd_001',
          nome: 'Prancha',
          categoria: 'Abdômen',
          musculos: ['Core'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 250,
        ),
      ];
    }

    if (objetivo == 'Força') {
      return [
        _exercicio(
          id: 'ia_forca_001',
          nome: 'Supino Reto',
          categoria: 'Peito',
          musculos: ['Peitoral', 'Tríceps'],
          equipamentos: ['Barra', 'Banco'],
          locais: ['Academia'],
          caloriasHora: 400,
        ),
        _exercicio(
          id: 'ia_forca_002',
          nome: 'Agachamento Livre',
          categoria: 'Perna',
          musculos: ['Quadríceps', 'Glúteos'],
          equipamentos: ['Barra'],
          locais: ['Academia'],
          caloriasHora: 500,
        ),
        _exercicio(
          id: 'ia_forca_003',
          nome: 'Levantamento Terra',
          categoria: 'Costas',
          musculos: ['Costas', 'Posterior de Coxa'],
          equipamentos: ['Barra'],
          locais: ['Academia'],
          caloriasHora: 550,
        ),
      ];
    }

    if (objetivo == 'Calistenia') {
      return [
        _exercicio(
          id: 'ia_calis_001',
          nome: 'Flexão de Braços',
          categoria: 'Peito',
          musculos: ['Peitoral', 'Tríceps'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 320,
        ),
        _exercicio(
          id: 'ia_calis_002',
          nome: 'Barra Fixa',
          categoria: 'Costas',
          musculos: ['Costas', 'Bíceps'],
          equipamentos: ['Barra Fixa'],
          locais: ['Casa', 'Academia'],
          caloriasHora: 360,
        ),
        _exercicio(
          id: 'ia_calis_003',
          nome: 'Agachamento Livre',
          categoria: 'Perna',
          musculos: ['Quadríceps', 'Glúteos'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 300,
        ),
      ];
    }

    if (objetivo == 'Resistência') {
      return [
        _exercicio(
          id: 'ia_res_001',
          nome: 'Polichinelo',
          categoria: 'Cardio',
          musculos: ['Corpo Inteiro'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 450,
        ),
        _exercicio(
          id: 'ia_res_002',
          nome: 'Flexão de Braços',
          categoria: 'Peito',
          musculos: ['Peitoral', 'Tríceps'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 320,
        ),
        _exercicio(
          id: 'ia_res_003',
          nome: 'Prancha',
          categoria: 'Abdômen',
          musculos: ['Core'],
          equipamentos: [],
          locais: ['Casa', 'Academia'],
          caloriasHora: 250,
        ),
      ];
    }

    return [
      _exercicio(
        id: 'ia_hip_001',
        nome: 'Supino Reto',
        categoria: 'Peito',
        musculos: ['Peitoral'],
        equipamentos: ['Barra', 'Banco'],
        locais: ['Academia'],
        caloriasHora: 400,
      ),
      _exercicio(
        id: 'ia_hip_002',
        nome: 'Puxada Frontal',
        categoria: 'Costas',
        musculos: ['Costas', 'Bíceps'],
        equipamentos: ['Polia'],
        locais: ['Academia'],
        caloriasHora: 350,
      ),
      _exercicio(
        id: 'ia_hip_003',
        nome: 'Agachamento Livre',
        categoria: 'Perna',
        musculos: ['Quadríceps', 'Glúteos'],
        equipamentos: ['Barra'],
        locais: ['Academia'],
        caloriasHora: 500,
      ),
    ];
  }

  ExercicioModel _exercicio({
    required String id,
    required String nome,
    required String categoria,
    required List<String> musculos,
    required List<String> equipamentos,
    required List<String> locais,
    required int caloriasHora,
  }) {
    return ExercicioModel(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      nome: nome,
      categoria: categoria,
      descricao: 'Exercício recomendado para o objetivo $objetivo.',
      comoExecutar:
          'Execute com controle, mantendo boa postura e amplitude segura.',
      cuidados: 'Evite cargas excessivas e interrompa em caso de dor.',
      musculos: musculos,
      equipamentos: equipamentos,
      locais: locais,
      dificuldade: experiencia,
      objetivo: objetivo,
      imagem: '',
      video: '',
      tags: [
        objetivo.toLowerCase(),
        categoria.toLowerCase(),
        ...musculos.map((e) => e.toLowerCase()),
      ],
      caloriasHora: caloriasHora,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Gerador de Treino IA')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Monte seu treino',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha seus dados e a IA cria um treino salvo automaticamente em Meus Treinos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: pesoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: alturaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: idadeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Idade'),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: experiencia,
            decoration: const InputDecoration(labelText: 'Experiência'),
            items: const [
              DropdownMenuItem(value: 'Iniciante', child: Text('Iniciante')),
              DropdownMenuItem(
                value: 'Intermediário',
                child: Text('Intermediário'),
              ),
              DropdownMenuItem(value: 'Avançado', child: Text('Avançado')),
            ],
            onChanged: (value) {
              setState(() {
                experiencia = value ?? experiencia;
              });
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: objetivo,
            decoration: const InputDecoration(labelText: 'Objetivo'),
            items: const [
              DropdownMenuItem(
                value: 'Hipertrofia',
                child: Text('Hipertrofia'),
              ),
              DropdownMenuItem(
                value: 'Emagrecimento',
                child: Text('Emagrecimento'),
              ),
              DropdownMenuItem(
                value: 'Resistência',
                child: Text('Resistência'),
              ),
              DropdownMenuItem(value: 'Calistenia', child: Text('Calistenia')),
              DropdownMenuItem(value: 'Força', child: Text('Força')),
            ],
            onChanged: (value) {
              setState(() {
                objetivo = value ?? objetivo;
              });
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: divisao,
            decoration: const InputDecoration(labelText: 'Tipo de treino'),
            isExpanded: true,
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
          if (divisao == 'Personalizado') ...[
            const SizedBox(height: 15),
            TextField(
              controller: divisaoPersonalizadaController,
              decoration: const InputDecoration(
                labelText: 'Divisao personalizada',
                hintText: 'Ex: A Peito, B Costas, C Pernas',
              ),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: carregando ? null : _gerarTreino,
            icon: carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(carregando ? 'Gerando...' : 'Gerar Treino'),
          ),
        ],
      ),
    );
  }
}
