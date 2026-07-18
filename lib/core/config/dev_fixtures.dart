import '../../models/achievement_model.dart';
import '../../models/coach_insight_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/fitai_meta_model.dart';
import '../../models/fitai_notification_model.dart';
import '../../models/historico_treino_model.dart';
import '../../models/treino_model.dart';
import '../../services/ia_evolutiva_service.dart';

class DevUserFixture {
  const DevUserFixture({
    required this.name,
    required this.email,
    required this.premium,
    required this.level,
    required this.xp,
  });

  final String name;
  final String email;
  final bool premium;
  final int level;
  final int xp;
}

class DevRunningFixture {
  const DevRunningFixture({
    required this.distanceKm,
    required this.averageSpeed,
    required this.elapsedSeconds,
  });

  final double distanceKm;
  final double averageSpeed;
  final int elapsedSeconds;
}

/// Fixtures exclusivas de debug. Elas sao criadas em memoria e nunca salvas.
abstract final class DevFixtures {
  static const user = DevUserFixture(
    name: 'Gabriel',
    email: 'gabriel@fitia.dev',
    premium: true,
    level: 18,
    xp: 2450,
  );

  static const running = DevRunningFixture(
    distanceKm: 5.4,
    averageSpeed: 9.1,
    elapsedSeconds: 2130,
  );

  static const int steps = 7542;

  static List<TreinoModel> get workouts => [_workout()];

  static List<HistoricoTreinoModel> get workoutHistory {
    final now = DateTime.now();
    return [
      HistoricoTreinoModel(
        id: 'dev-workout-history-1',
        nomeTreino: 'Upper A',
        dataHora: now.subtract(const Duration(days: 1)),
        tempoSegundos: 2760,
        tempoFormatado: '46:00',
        exerciciosTotais: 6,
        exerciciosConcluidos: 6,
        xpGanho: 180,
        caloriasEstimadas: 420,
        objetivo: 'Hipertrofia',
        nivel: 'Intermediario',
        seriesConcluidas: 18,
        volumeTotal: 6840,
      ),
      HistoricoTreinoModel(
        id: 'dev-workout-history-2',
        nomeTreino: 'Lower A',
        dataHora: now.subtract(const Duration(days: 3)),
        tempoSegundos: 3000,
        tempoFormatado: '50:00',
        exerciciosTotais: 6,
        exerciciosConcluidos: 6,
        xpGanho: 180,
        caloriasEstimadas: 440,
        objetivo: 'Hipertrofia',
        nivel: 'Intermediario',
        seriesConcluidas: 18,
        volumeTotal: 7130,
      ),
    ];
  }

  static List<CoachInsightModel> get coachInsights => const [
    CoachInsightModel(
      id: 'dev-coach-progress',
      titulo: 'Progressao consistente',
      descricao:
          'Voce concluiu suas ultimas sessoes. Mantenha a carga com boa tecnica.',
      acao: 'Priorize a proxima sessao Upper A.',
      prioridade: CoachInsightPrioridade.media,
      categoria: CoachInsightCategoria.progressao,
      icone: 'trending_up',
    ),
  ];

  static FitaiMetasResumo get goals => const FitaiMetasResumo(
    metas: [
      FitaiMetaModel(
        id: 'dev-goal-workouts',
        titulo: 'Treinos da semana',
        descricao: 'Complete 3 treinos nesta semana.',
        valorAtual: 2,
        valorObjetivo: 3,
        categoria: FitaiMetaCategoria.treinos,
        status: FitaiMetaStatus.emAndamento,
        progresso: 0.67,
        unidade: 'treinos',
        tempoRestante: '4 dias restantes',
        estimativa: 'No ritmo atual, voce conclui a meta.',
        coachDica: 'Programe uma sessao curta para amanha.',
      ),
      FitaiMetaModel(
        id: 'dev-goal-steps',
        titulo: 'Passos diarios',
        descricao: 'Atingir 10.000 passos hoje.',
        valorAtual: 7542,
        valorObjetivo: 10000,
        categoria: FitaiMetaCategoria.passos,
        status: FitaiMetaStatus.emAndamento,
        progresso: 0.75,
        unidade: 'passos',
        tempoRestante: 'Hoje',
        estimativa: 'Faltam 2.458 passos.',
        coachDica: 'Uma caminhada curta completa sua meta.',
      ),
    ],
  );

  static List<AchievementModel> get achievements => [
    AchievementModel(
      id: 'dev-achievement-streak',
      nome: 'Em sequencia',
      descricao: 'Treinou por 3 semanas consecutivas.',
      icone: 'local_fire_department',
      categoria: 'Consistencia',
      desbloqueada: true,
      data: DateTime.now().subtract(const Duration(days: 1)),
    ),
    const AchievementModel(
      id: 'dev-achievement-distance',
      nome: 'Primeiros 10 km',
      descricao: 'Complete 10 km em corridas.',
      icone: 'directions_run',
      categoria: 'Corridas',
      desbloqueada: false,
    ),
  ];

  static List<FitaiNotificationModel> get notifications => [
    FitaiNotificationModel(
      id: 'dev-notification-workout',
      titulo: 'Treino de hoje',
      descricao: 'Upper A esta pronto para voce iniciar.',
      categoria: FitaiNotificationCategoria.treinos,
      icone: 'fitness_center',
      data: DateTime.now(),
      acao: 'treino:dev-upper-a',
    ),
  ];

  static Map<String, num> get nutrition => const {
    'calories': 1840,
    'proteinGrams': 128,
  };

  static Map<String, Object> get premium => const {
    'isPremium': true,
    'plan': 'FitIA Premium',
  };

  static IaEvolutivaRecomendacao recommendation(TreinoModel workout) {
    return IaEvolutivaRecomendacao(
      titulo: 'Ritmo ideal para hoje',
      texto: 'Continue com ${workout.nome} e mantenha a execucao controlada.',
      motivo: 'Fixture local de desenvolvimento.',
      intensidade: 'moderado',
      treinoRecomendado: workout,
    );
  }

  static TreinoModel _workout() {
    final exercises = [
      ExercicioModel(
        id: 'dev-supino-reto',
        nome: 'Supino reto',
        categoria: 'Peito',
        descricao: 'Exercicio composto para peitoral.',
        comoExecutar: 'Controle a descida e mantenha os pes apoiados.',
        cuidados: 'Use uma carga compativel com sua tecnica.',
        musculos: const ['Peito'],
        musculosSecundarios: const ['Triceps', 'Ombros'],
        equipamentos: const ['Barra', 'Banco'],
        locais: const ['Academia'],
        dificuldade: 'Intermediario',
        objetivo: 'Hipertrofia',
        imagem:
            'assets/gifs/barbell_banded_weighted_plate_bench_press_male.gif',
        video: '',
        tags: const ['composto'],
        caloriasHora: 280,
        series: 4,
        repeticoes: '8-10',
        descansoSegundos: 90,
      ),
      ExercicioModel(
        id: 'dev-remada-baixa',
        nome: 'Remada baixa',
        categoria: 'Costas',
        descricao: 'Exercicio para dorsais e costas.',
        comoExecutar: 'Puxe com os cotovelos e controle o retorno.',
        cuidados: 'Evite compensar com a lombar.',
        musculos: const ['Costas'],
        equipamentos: const ['Maquina'],
        locais: const ['Academia'],
        dificuldade: 'Intermediario',
        objetivo: 'Hipertrofia',
        imagem: 'assets/gifs/band_seated_row.gif',
        video: '',
        tags: const ['composto'],
        caloriasHora: 240,
        series: 4,
        repeticoes: '10-12',
        descansoSegundos: 75,
      ),
    ];
    return TreinoModel(
      id: 'dev-upper-a',
      nome: 'Upper A',
      descricao: 'Peito, costas e bracos.',
      objetivo: 'Hipertrofia',
      nivel: 'Intermediario',
      divisao: 'Upper / Lower',
      tempoEstimado: 45,
      diasPorSemana: 4,
      local: 'Academia',
      equipamentos: const ['Barra', 'Halteres', 'Maquinas'],
      gruposPrioritarios: const ['Peito', 'Costas'],
      planoDias: const [
        TreinoDiaModel(
          codigo: 'A',
          nome: 'Peito e Costas',
          ordem: 1,
          exercicioIds: ['dev-supino-reto', 'dev-remada-baixa'],
        ),
      ],
      criadoPorIA: true,
      exercicios: exercises,
      dataCriacao: DateTime.now().toIso8601String(),
      origem: 'developer_mode',
    );
  }
}
