import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

enum CreatePlanAction { ia, manual }

class CreatePlanBottomSheet extends StatelessWidget {
  const CreatePlanBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Criar Novo Plano",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              "Escolha como deseja montar sua ficha.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            _CreatePlanOption(
              icon: Icons.auto_awesome_rounded,
              title: "Criar Plano com IA",
              subtitle: "O FitIA monta uma ficha com base no seu objetivo.",
              gradient: AppColors.gradientPrimary,
              darkText: true,
              onTap: () => Navigator.pop(context, CreatePlanAction.ia),
            ),
            const SizedBox(height: 12),
            _CreatePlanOption(
              icon: Icons.edit_note_rounded,
              title: "Criar Plano Manual",
              subtitle: "Escolha exercicios e organize sua propria ficha.",
              onTap: () => Navigator.pop(context, CreatePlanAction.manual),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient? gradient;
  final bool darkText;
  final VoidCallback onTap;

  const _CreatePlanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = darkText ? Colors.black : Colors.white;
    final subtitleColor = darkText ? Colors.black87 : Colors.white70;
    final iconColor = darkText ? Colors.black : AppColors.primary;
    final iconBackground = darkText
        ? Colors.black.withAlpha(24)
        : AppColors.primary.withAlpha(28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AppGradientCard(
          gradient: gradient,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: darkText ? Colors.black54 : Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
