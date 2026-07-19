import '../../../models/treino_model.dart';

TreinoModel copyOfficialPlan(
  TreinoModel source, {
  String? id,
  String? name,
  String? description,
  String? goal,
  String? level,
  String? split,
  List<TreinoDiaModel>? days,
  String? createdAt,
}) {
  return TreinoModel(
    id: id ?? source.id,
    nome: name ?? source.nome,
    descricao: description ?? source.descricao,
    objetivo: goal ?? source.objetivo,
    nivel: level ?? source.nivel,
    divisao: split ?? source.divisao,
    tempoEstimado: source.tempoEstimado,
    diasPorSemana: days?.length ?? source.diasPorSemana,
    local: source.local,
    equipamentos: source.equipamentos,
    gruposPrioritarios: source.gruposPrioritarios,
    lesoesRestricoes: source.lesoesRestricoes,
    exerciciosFavoritos: source.exerciciosFavoritos,
    exerciciosEvitados: source.exerciciosEvitados,
    observacoes: source.observacoes,
    diaPlano: source.diaPlano,
    grupoDia: source.grupoDia,
    ordemDia: source.ordemDia,
    planoDias: days ?? source.planoDias,
    criadoPorIA: source.criadoPorIA,
    exercicios: source.exercicios,
    dataCriacao: createdAt ?? source.dataCriacao,
    origem: source.origem,
    readyPlanId: source.readyPlanId,
  );
}
