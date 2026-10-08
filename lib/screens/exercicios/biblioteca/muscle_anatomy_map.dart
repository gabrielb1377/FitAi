import 'package:flutter/material.dart';

import '../../../core/exercises/muscle_anatomy_taxonomy.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';

/// Lightweight original front/back anatomy views for an exercise detail.
///
/// The source labels stay on [ExercicioModel]; this widget only renders their
/// exact taxonomy mapping and keeps unmatched terms available as text.
class MuscleAnatomyMap extends StatelessWidget {
  const MuscleAnatomyMap({super.key, required this.exercise});

  final ExercicioModel exercise;

  static final Set<String> renderableRegionIds = Set.unmodifiable(
    _MuscleAnatomyPainter.renderableRegionIds,
  );

  @override
  Widget build(BuildContext context) {
    final mapping = const ExerciseMuscleMapper().map(exercise);
    final regions = MuscleAnatomyTaxonomy.regions;
    final primary = mapping.primaryMuscles.toSet();
    final secondary = mapping.secondaryMuscles.toSet();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Músculos trabalhados',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FitSpacing.s12),
        Wrap(
          spacing: FitSpacing.s16,
          runSpacing: FitSpacing.s8,
          children: [
            _LegendItem(
              color: scheme.primary,
              label: 'Primário',
              pattern: 'sólido',
            ),
            _LegendItem(
              color: scheme.tertiary,
              label: 'Secundário',
              pattern: 'listrado',
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s12),
        if (!mapping.isVisualSafe)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(FitSpacing.s12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: FitRadius.mediumBorder,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'O mapa foi omitido para evitar uma indicação anatômica imprecisa. '
              'Os músculos informados no catálogo continuam listados abaixo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: FitSpacing.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AnatomyViewCard(
                view: MuscleAnatomyView.front,
                title: 'Frente',
                regions: regions,
                primaryIds: mapping.isVisualSafe ? primary : const {},
                secondaryIds: mapping.isVisualSafe ? secondary : const {},
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: _AnatomyViewCard(
                view: MuscleAnatomyView.back,
                title: 'Costas',
                regions: regions,
                primaryIds: mapping.isVisualSafe ? primary : const {},
                secondaryIds: mapping.isVisualSafe ? secondary : const {},
              ),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s12),
        if (mapping.primaryMuscles.isNotEmpty) ...[
          _RoleHeading(label: 'Músculos primários'),
          const SizedBox(height: FitSpacing.s4),
          for (final id in mapping.primaryMuscles)
            _MuscleLabelRow(
              label: MuscleAnatomyTaxonomy.byId[id]!.label,
              role: 'Primário',
              color: scheme.primary,
            ),
        ],
        if (mapping.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: FitSpacing.s8),
          _RoleHeading(label: 'Músculos secundários'),
          const SizedBox(height: FitSpacing.s4),
          for (final id in mapping.secondaryMuscles)
            _MuscleLabelRow(
              label: MuscleAnatomyTaxonomy.byId[id]!.label,
              role: 'Secundário',
              color: scheme.tertiary,
            ),
        ],
        if (mapping.hasRenderableRegions) ...[
          for (final label in mapping.ambiguousLabels)
            _MuscleLabelRow(
              label: label,
              role: 'Região não especificada',
              color: scheme.outline,
            ),
          for (final label in mapping.unmappedLabels)
            _MuscleLabelRow(
              label: label,
              role: 'Sem região no mapa',
              color: scheme.outline,
            ),
        ] else ...[
          Text(
            exercise.musculos.isEmpty && exercise.musculosSecundarios.isEmpty
                ? 'Músculos ainda não informados para este exercício.'
                : 'Nenhuma região pôde ser mapeada com segurança.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final label in exercise.musculos)
            _MuscleLabelRow(
              label: label,
              role: 'Primário informado',
              color: scheme.outline,
            ),
          for (final label in exercise.musculosSecundarios)
            _MuscleLabelRow(
              label: label,
              role: 'Secundário informado',
              color: scheme.outline,
            ),
        ],
      ],
    );
  }
}

class _AnatomyViewCard extends StatelessWidget {
  const _AnatomyViewCard({
    required this.view,
    required this.title,
    required this.regions,
    required this.primaryIds,
    required this.secondaryIds,
  });

  final MuscleAnatomyView view;
  final String title;
  final List<MuscleRegion> regions;
  final Set<String> primaryIds;
  final Set<String> secondaryIds;

  @override
  Widget build(BuildContext context) {
    final applicable = regions.where((region) => region.views.contains(view));
    final highlighted = applicable
        .where(
          (region) =>
              primaryIds.contains(region.id) ||
              secondaryIds.contains(region.id),
        )
        .map((region) => region.label)
        .toList(growable: false);
    return Column(
      children: [
        Semantics(header: true, child: Text(title)),
        const SizedBox(height: FitSpacing.s4),
        Semantics(
          image: true,
          label: highlighted.isEmpty
              ? 'Mapa anatômico simplificado, vista $title, sem região destacada.'
              : 'Mapa anatômico simplificado, vista $title. '
                    'Regiões relacionadas: ${highlighted.join(', ')}.',
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(double.infinity, 204),
                painter: _MuscleAnatomyPainter(
                  view: view,
                  primaryIds: primaryIds,
                  secondaryIds: secondaryIds,
                  scheme: Theme.of(context).colorScheme,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.pattern,
  });

  final Color color;
  final String label;
  final String pattern;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, preenchimento $pattern',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: FitSpacing.s12,
              height: FitSpacing.s12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(FitRadius.controlSmall),
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _RoleHeading extends StatelessWidget {
  const _RoleHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _MuscleLabelRow extends StatelessWidget {
  const _MuscleLabelRow({
    required this.label,
    required this.role,
    required this.color,
  });

  final String label;
  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
      child: Semantics(
        label: '$label — $role',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: FitSpacing.s4),
                child: Icon(Icons.circle, size: FitSpacing.s8, color: color),
              ),
              const SizedBox(width: FitSpacing.s8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: FitSpacing.s8),
              Text(role, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleAnatomyPainter extends CustomPainter {
  const _MuscleAnatomyPainter({
    required this.view,
    required this.primaryIds,
    required this.secondaryIds,
    required this.scheme,
  });

  final MuscleAnatomyView view;
  final Set<String> primaryIds;
  final Set<String> secondaryIds;
  final ColorScheme scheme;

  static const _frontIds = <String>{
    'chest',
    'upper_chest',
    'lower_chest',
    'serratus',
    'front_deltoid',
    'side_deltoid',
    'biceps',
    'brachialis',
    'forearms',
    'abs',
    'obliques',
    'hip_flexors',
    'adductors',
    'quadriceps',
    'calves',
    'neck',
    'tibialis',
    'hands',
  };

  static const _backIds = <String>{
    'side_deltoid',
    'rear_deltoid',
    'triceps',
    'forearms',
    'obliques',
    'calves',
    'traps',
    'upper_back',
    'lats',
    'lower_back',
    'glutes',
    'hamstrings',
    'neck',
    'rotator_cuff',
    'spinal_erectors',
    'hands',
  };

  static final Map<String, List<Path>> _frontShapes = _buildShapes(front: true);
  static final Map<String, List<Path>> _backShapes = _buildShapes(front: false);
  static final Set<String> renderableRegionIds = Set.unmodifiable({
    ..._frontShapes.keys,
    ..._backShapes.keys,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 210);
    _drawSilhouette(canvas);
    final shapes = view == MuscleAnatomyView.front ? _frontShapes : _backShapes;
    final ids = view == MuscleAnatomyView.front ? _frontIds : _backIds;
    for (final id in ids) {
      final paths = shapes[id] ?? const <Path>[];
      for (final path in paths) {
        final role = primaryIds.contains(id)
            ? MuscleAnatomyRole.primary
            : secondaryIds.contains(id)
            ? MuscleAnatomyRole.secondary
            : null;
        final color = role == MuscleAnatomyRole.primary
            ? scheme.primary
            : role == MuscleAnatomyRole.secondary
            ? scheme.tertiary
            : scheme.surfaceContainerHighest;
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        if (role == MuscleAnatomyRole.secondary) {
          canvas.save();
          canvas.clipPath(path);
          final hatch = Paint()
            ..color = scheme.onTertiary.withValues(alpha: 0.34)
            ..strokeWidth = 1.25;
          for (var offset = -200.0; offset < 220; offset += 8) {
            canvas.drawLine(
              Offset(offset, 0),
              Offset(offset + 210, 210),
              hatch,
            );
          }
          canvas.restore();
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = scheme.outlineVariant
            ..strokeWidth = 1.1
            ..style = PaintingStyle.stroke,
        );
      }
    }
    canvas.restore();
  }

  void _drawSilhouette(Canvas canvas) {
    final base = Paint()
      ..color = scheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1.35
      ..style = PaintingStyle.stroke;
    final shapes = <Path>[
      Path()..addOval(const Rect.fromLTRB(42, 3, 58, 20)),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(45, 18, 55, 29),
          const Radius.circular(4),
        ),
      ),
      Path()
        ..moveTo(34, 25)
        ..quadraticBezierTo(50, 19, 66, 25)
        ..lineTo(70, 53)
        ..quadraticBezierTo(66, 64, 62, 77)
        ..lineTo(38, 77)
        ..quadraticBezierTo(34, 64, 30, 53)
        ..close(),
      Path()
        ..moveTo(34, 27)
        ..lineTo(25, 32)
        ..lineTo(19, 76)
        ..lineTo(26, 78)
        ..lineTo(39, 40)
        ..close(),
      Path()
        ..moveTo(66, 27)
        ..lineTo(75, 32)
        ..lineTo(81, 76)
        ..lineTo(74, 78)
        ..lineTo(61, 40)
        ..close(),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(18, 73, 28, 102),
          const Radius.circular(5),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(72, 73, 82, 102),
          const Radius.circular(5),
        ),
      ),
      Path()
        ..moveTo(39, 72)
        ..lineTo(61, 72)
        ..lineTo(59, 119)
        ..lineTo(53, 125)
        ..lineTo(47, 125)
        ..lineTo(41, 119)
        ..close(),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(40, 118, 50, 174),
          const Radius.circular(6),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(50, 118, 60, 174),
          const Radius.circular(6),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(40, 168, 49, 201),
          const Radius.circular(5),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(51, 168, 60, 201),
          const Radius.circular(5),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(34, 198, 50, 207),
          const Radius.circular(4),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(50, 198, 66, 207),
          const Radius.circular(4),
        ),
      ),
    ];
    for (final shape in shapes) {
      canvas.drawPath(shape, base);
      canvas.drawPath(shape, outline);
    }
  }

  static Map<String, List<Path>> _buildShapes({required bool front}) {
    Path oval(double left, double top, double right, double bottom) =>
        Path()..addOval(Rect.fromLTRB(left, top, right, bottom));

    Path rounded(double left, double top, double right, double bottom) =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, bottom),
            const Radius.circular(3),
          ),
        );

    if (front) {
      return {
        'chest': [oval(38, 27, 49, 38), oval(51, 27, 62, 38)],
        'upper_chest': [oval(38, 24, 49, 31), oval(51, 24, 62, 31)],
        'lower_chest': [oval(38, 33, 49, 40), oval(51, 33, 62, 40)],
        'serratus': [oval(32, 37, 39, 49), oval(61, 37, 68, 49)],
        'front_deltoid': [oval(29, 27, 38, 39), oval(62, 27, 71, 39)],
        'side_deltoid': [oval(27, 31, 34, 43), oval(66, 31, 73, 43)],
        'biceps': [oval(24, 43, 30, 59), oval(70, 43, 76, 59)],
        'brachialis': [oval(24, 51, 30, 60), oval(70, 51, 76, 60)],
        'forearms': [oval(19, 64, 26, 84), oval(74, 64, 81, 84)],
        'hands': [oval(17, 82, 25, 91), oval(75, 82, 83, 91)],
        'abs': [rounded(43, 42, 57, 69)],
        'obliques': [rounded(34, 44, 42, 66), rounded(58, 44, 66, 66)],
        'hip_flexors': [oval(41, 68, 49, 81), oval(51, 68, 59, 81)],
        'adductors': [oval(47, 86, 53, 113)],
        'quadriceps': [oval(39, 82, 49, 116), oval(51, 82, 61, 116)],
        'calves': [oval(40, 147, 49, 170), oval(51, 147, 60, 170)],
        'tibialis': [rounded(41, 150, 48, 169), rounded(52, 150, 59, 169)],
        'neck': [rounded(45, 19, 55, 28)],
      };
    }
    return {
      'side_deltoid': [oval(27, 30, 34, 42), oval(66, 30, 73, 42)],
      'rear_deltoid': [oval(30, 29, 39, 41), oval(61, 29, 70, 41)],
      'triceps': [oval(24, 43, 30, 60), oval(70, 43, 76, 60)],
      'forearms': [oval(19, 64, 26, 84), oval(74, 64, 81, 84)],
      'hands': [oval(17, 82, 25, 91), oval(75, 82, 83, 91)],
      'traps': [
        oval(42, 23, 58, 39),
        Path()
          ..moveTo(42, 25)
          ..lineTo(31, 31)
          ..lineTo(42, 35)
          ..close(),
        Path()
          ..moveTo(58, 25)
          ..lineTo(69, 31)
          ..lineTo(58, 35)
          ..close(),
      ],
      'upper_back': [rounded(42, 36, 58, 53)],
      'lats': [oval(32, 38, 42, 61), oval(58, 38, 68, 61)],
      'rotator_cuff': [oval(34, 30, 42, 40), oval(58, 30, 66, 40)],
      'obliques': [rounded(34, 45, 41, 65), rounded(59, 45, 66, 65)],
      'lower_back': [rounded(43, 57, 57, 72)],
      'spinal_erectors': [rounded(48, 41, 52, 75)],
      'glutes': [oval(39, 72, 50, 91), oval(50, 72, 61, 91)],
      'hamstrings': [oval(39, 91, 49, 124), oval(51, 91, 61, 124)],
      'calves': [oval(40, 146, 49, 170), oval(51, 146, 60, 170)],
      'neck': [rounded(45, 19, 55, 28)],
    };
  }

  @override
  bool shouldRepaint(covariant _MuscleAnatomyPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.primaryIds != primaryIds ||
      oldDelegate.secondaryIds != secondaryIds ||
      oldDelegate.scheme != scheme;
}
