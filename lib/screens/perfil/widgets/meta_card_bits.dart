import 'package:flutter/material.dart';

import '../../../models/fitai_meta_model.dart';
import '../../../theme/app_theme.dart';

class MetaValueTile extends StatelessWidget {
  final String label;
  final String value;

  const MetaValueTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class MetaStatusPill extends StatelessWidget {
  final FitaiMetaModel meta;
  final Color color;

  const MetaStatusPill({super.key, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _statusColor.withAlpha(90)),
      ),
      child: Text(
        meta.statusLabel,
        style: TextStyle(color: _statusColor, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color get _statusColor {
    switch (meta.status) {
      case FitaiMetaStatus.concluida:
        return Colors.greenAccent;
      case FitaiMetaStatus.atrasada:
        return Colors.orangeAccent;
      case FitaiMetaStatus.pendente:
        return AppColors.textSecondary;
      case FitaiMetaStatus.emAndamento:
        return color;
    }
  }
}

class MetaInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const MetaInfoLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class MetaCoachLine extends StatelessWidget {
  final String text;
  final Color color;

  const MetaCoachLine({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
