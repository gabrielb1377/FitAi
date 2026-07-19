import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/ready_plan_model.dart';
import '../../../models/treino_model.dart';
import '../widgets/plans/plan_media.dart';

abstract final class OfficialPlanColors {
  static const background = Color(0xFF071015);
  static const surface = Color(0xFF0D171D);
  static const surfaceRaised = Color(0xFF111C22);
  static const surfaceSelected = Color(0xFF14231E);
  static const border = Color(0xFF1A2931);
  static const borderStrong = Color(0xFF31414A);
  static const green = Color(0xFF17D968);
  static const greenDark = Color(0xFF0FB955);
  static const teal = Color(0xFF159A9C);
  static const text = Color(0xFFF4F7F5);
  static const textMuted = Color(0xFF9AA6AB);
  static const textDim = Color(0xFF65737A);
  static const warning = Color(0xFFFFC438);
  static const danger = Color(0xFFFF4D48);
}

class OfficialPlanViewport extends StatelessWidget {
  const OfficialPlanViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OfficialPlanColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: child,
        ),
      ),
    );
  }
}

class OfficialPlanHeader extends StatelessWidget {
  const OfficialPlanHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OfficialPlanIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Voltar',
                  onPressed: onBack!,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OfficialPlanColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ),
      ),
    );
  }
}

class OfficialPlanIconButton extends StatelessWidget {
  const OfficialPlanIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = OfficialPlanColors.text,
    this.outlined = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              decoration: outlined
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OfficialPlanColors.border),
                    )
                  : null,
              alignment: Alignment.center,
              child: Icon(icon, size: 21, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class OfficialPlanTabs extends StatelessWidget {
  const OfficialPlanTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OfficialPlanColors.border)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: labels[index],
              child: InkWell(
                onTap: () => onSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          labels[index],
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selected
                                    ? OfficialPlanColors.green
                                    : OfficialPlanColors.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: FitDuration.fast,
                      height: 2,
                      width: selected ? 102 : 0,
                      color: OfficialPlanColors.green,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class OfficialPlanSearch extends StatelessWidget {
  const OfficialPlanSearch({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Buscar planos...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: OfficialPlanColors.text),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: OfficialPlanColors.textDim),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: OfficialPlanColors.textDim,
          ),
          filled: true,
          fillColor: OfficialPlanColors.surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: OfficialPlanColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: OfficialPlanColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: OfficialPlanColors.green),
          ),
        ),
      ),
    );
  }
}

class OfficialPlanSurface extends StatelessWidget {
  const OfficialPlanSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.color = OfficialPlanColors.surfaceRaised,
    this.radius = 8,
    this.borderColor = OfficialPlanColors.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class OfficialPlanProgressRing extends StatelessWidget {
  const OfficialPlanProgressRing({
    super.key,
    required this.value,
    this.size = 52,
    this.strokeWidth = 5,
  });

  final double value;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '${(safeValue * 100).round()} por cento concluído',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: safeValue,
                strokeWidth: strokeWidth,
                backgroundColor: OfficialPlanColors.borderStrong,
                valueColor: const AlwaysStoppedAnimation(
                  OfficialPlanColors.green,
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${(safeValue * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: OfficialPlanColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfficialPlanPrimaryButton extends StatelessWidget {
  const OfficialPlanPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: OfficialPlanColors.greenDark,
          disabledBackgroundColor: OfficialPlanColors.surfaceRaised,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class OfficialPlanMedia extends StatelessWidget {
  const OfficialPlanMedia({
    super.key,
    required this.plan,
    this.width,
    this.height,
    this.radius = 7,
    this.fit = BoxFit.cover,
  });

  final TreinoModel plan;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return PlanMedia(
      plan: plan,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class OfficialReadyPlanMedia extends StatelessWidget {
  const OfficialReadyPlanMedia({
    super.key,
    required this.plan,
    this.width,
    this.height,
    this.radius = 7,
    this.fit = BoxFit.cover,
  });

  final ReadyPlanModel plan;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cover = plan.cover.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: OfficialPlanColors.surfaceRaised,
          child: cover.isEmpty ? _fallback() : _image(cover),
        ),
      ),
    );
  }

  Widget _image(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.asset(path, fit: fit, errorBuilder: (_, _, _) => _fallback());
  }

  Widget _fallback() {
    return const Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 32,
        color: OfficialPlanColors.green,
      ),
    );
  }
}

class OfficialPlanChoiceChip extends StatelessWidget {
  const OfficialPlanChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: FitDuration.fast,
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? OfficialPlanColors.greenDark
                : OfficialPlanColors.surfaceRaised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? OfficialPlanColors.green
                  : OfficialPlanColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: OfficialPlanColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class OfficialPlanLabeledField extends StatelessWidget {
  const OfficialPlanLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: OfficialPlanColors.textMuted),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration officialPlanInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: OfficialPlanColors.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    hintStyle: const TextStyle(color: OfficialPlanColors.textDim, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: OfficialPlanColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: OfficialPlanColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: OfficialPlanColors.green),
    ),
  );
}
