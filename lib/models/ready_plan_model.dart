import 'ready_plan_day_model.dart';

class ReadyPlanModel {
  final String id;
  final String name;
  final String description;
  final String goal;
  final String level;
  final String split;
  final int daysPerWeek;
  final int durationWeeks;
  final int estimatedMinutes;
  final String location;
  final List<String> equipment;
  final List<String> tags;
  final bool featured;
  final bool active;
  final String cover;
  final String category;
  final List<ReadyPlanDayModel> days;

  const ReadyPlanModel({
    required this.id,
    required this.name,
    this.description = '',
    this.goal = '',
    this.level = '',
    this.split = '',
    this.daysPerWeek = 0,
    this.durationWeeks = 0,
    this.estimatedMinutes = 0,
    this.location = '',
    this.equipment = const [],
    this.tags = const [],
    this.featured = false,
    this.active = true,
    this.cover = '',
    this.category = '',
    this.days = const [],
  });

  factory ReadyPlanModel.fromJson(Map<String, dynamic> json) {
    final category = _string(
      json['category'],
      fallback: _string(json['categoria']),
    );
    final goal = _string(json['goal'], fallback: _string(json['objetivo']));
    final split = _string(json['split'], fallback: _string(json['divisao']));
    final location = _string(
      json['location'],
      fallback: _string(json['local']),
    );
    final tags = _stringList(json['tags']);

    return ReadyPlanModel(
      id: _string(json['id']),
      name: _string(
        json['name'],
        fallback: _string(json['nome'], fallback: 'Plano pronto'),
      ),
      description: _string(
        json['description'],
        fallback: _string(json['descricao']),
      ),
      goal: goal,
      level: _string(json['level'], fallback: _string(json['nivel'])),
      split: split,
      daysPerWeek: _int(
        json['daysPerWeek'],
        fallback: _int(json['diasPorSemana']),
      ),
      durationWeeks: _int(
        json['durationWeeks'],
        fallback: _int(json['duracaoSemanas']),
      ),
      estimatedMinutes: _int(
        json['estimatedMinutes'],
        fallback: _int(json['tempoEstimado']),
      ),
      location: location.isEmpty ? _locationForCategory(category) : location,
      equipment: _stringList(json['equipment'] ?? json['equipamentos']),
      tags: tags.isEmpty ? _defaultTags(category, goal, split) : tags,
      featured: _bool(json['featured'], fallback: _bool(json['destaque'])),
      active: _bool(
        json['active'],
        fallback: _bool(json['ativo'], fallback: true),
      ),
      cover: _string(json['cover'], fallback: _string(json['capa'])),
      category: category,
      days: _maps(
        json['days'] ?? json['dias'],
      ).map(ReadyPlanDayModel.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'goal': goal,
    'level': level,
    'split': split,
    'daysPerWeek': daysPerWeek,
    'durationWeeks': durationWeeks,
    'estimatedMinutes': estimatedMinutes,
    'location': location,
    'equipment': equipment,
    'tags': tags,
    'featured': featured,
    'active': active,
    'cover': cover,
    'category': category,
    'days': days.map((day) => day.toJson()).toList(),
  };

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }

  static String _locationForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'casa':
      case 'calistenia':
        return 'Casa';
      default:
        return 'Academia';
    }
  }

  static List<String> _defaultTags(String category, String goal, String split) {
    return [
      category,
      goal,
      split,
    ].where((item) => item.trim().isNotEmpty).toList();
  }
}
