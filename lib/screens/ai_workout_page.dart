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
  final treinoService = TreinoService.instance;

  String experiencia = 'Iniciante';
  String objetivo = 'Hipertrofia';
  bool carregando = false;

  @override
  void dispose() {
    pesoController.dispose();
    alturaController.dispose();
    idadeController.dispose();
    super.dispose();
  }

  Future<void> _gerarTreino() async {
    setState(() {
      carregando = true;
    });

    final exercicios = _exerciciosPorObjetivo(objetivo);

    final treino = TreinoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: 'Treino $objetivo',
      descricao: 'Treino gerado pela IA com base no objetivo $objetivo e nível $experiencia.',
      objetivo: objetivo,
      nivel: experiencia,
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

  List<ExercicioModel> _exerciciosPorObjetivo(String objetivo) {
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
      comoExecutar: 'Execute com controle, mantendo boa postura e amplitude segura.',
      cuidados: 'Evite cargas excessivas e interrompa em caso de dor.',
      musculos: musculos,
      equipamentos: equipamentos,
      locais: locais,
      dificuldade: experiencia,
      objetivo: objetivo,
      imagem: '',
      video: '',
      tags: [objetivo.toLowerCase(), categoria.toLowerCase(), ...musculos.map((e) => e.toLowerCase())],
      caloriasHora: caloriasHora,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gerador de Treino IA'),
      ),
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
              DropdownMenuItem(value: 'Intermediário', child: Text('Intermediário')),
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
              DropdownMenuItem(value: 'Hipertrofia', child: Text('Hipertrofia')),
              DropdownMenuItem(value: 'Emagrecimento', child: Text('Emagrecimento')),
              DropdownMenuItem(value: 'Resistência', child: Text('Resistência')),
              DropdownMenuItem(value: 'Calistenia', child: Text('Calistenia')),
              DropdownMenuItem(value: 'Força', child: Text('Força')),
            ],
            onChanged: (value) {
              setState(() {
                objetivo = value ?? objetivo;
              });
            },
          ),
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
