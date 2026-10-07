/// Validated server proposal. Cached data never grants execution authority.
class AiActionProposal {
  const AiActionProposal({required this.json});
  static const version = 'AiActionProposal/v1';
  final Map<String, dynamic> json;
  String get id => json['actionId'] as String;
  String get type => json['actionType'] as String;
  String get status => json['status'] as String;
  String get explanation => json['explanation'] as String;
  Map<String, dynamic> get payload =>
      Map<String, dynamic>.from(json['payload'] as Map);
  Map<String, dynamic> get preview =>
      Map<String, dynamic>.from(json['preview'] as Map);
  Map<String, dynamic>? get before => json['expectedBefore'] == null
      ? null
      : Map<String, dynamic>.from(json['expectedBefore'] as Map);
  Map<String, dynamic> get after =>
      Map<String, dynamic>.from(json['expectedAfter'] as Map);
  factory AiActionProposal.fromJson(Map<String, dynamic> json) {
    if (json['contractVersion'] != version ||
        [
          'actionId',
          'actionType',
          'status',
          'explanation',
        ].any((key) => json[key] is! String) ||
        json['payload'] is! Map ||
        json['preview'] is! Map ||
        ![
          'VALIDATED',
          'REJECTED',
          'CONFIRMED',
          'EXECUTED',
          'EXPIRED',
          'CANCELLED',
        ].contains(json['status'])) {
      throw const FormatException('Invalid action proposal.');
    }
    if (['VALIDATED', 'CONFIRMED', 'EXECUTED'].contains(json['status']) &&
        (![
              'USE_GENERATED_WORKOUT',
              'REPLACE_EXERCISE',
              'ADD_EXERCISE_TO_PLAN',
            ].contains(json['actionType']) ||
            json['expectedAfter'] is! Map)) {
      throw const FormatException('Invalid validated action.');
    }
    return AiActionProposal(json: Map.unmodifiable(json));
  }
}
