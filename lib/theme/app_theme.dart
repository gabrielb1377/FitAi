import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ─────────────────────────────────────────────
//  PALETA DE CORES
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Ranks
  static const rankBronze = Color(0xFFCD7F32);
  static const rankPrata = Color(0xFFC0C0C0);
  static const rankOuro = Color(0xFFFFD700);
  static const rankPlatina = Color(0xFFB0E0E6);
  static const rankDiamante = Color(0xFF00BCD4);

  // Primária — verde energia (inspirado Nike/Strava)
  static const primary = Color(0xFF00E676);
  static const primaryDark = Color(0xFF00C853);
  static const primaryLight = Color(0xFF69F0AE);

  // Fundo
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceVariant = Color(0xFF1E1E1E);
  static const card = Color(0xFF1A1A1A);

  // Texto
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const textHint = Color(0xFF616161);

  // Acentos
  static const accent1 = Color(0xFF448AFF); // azul
  static const accent2 = Color(0xFFFF6D00); // laranja
  static const accent3 = Color(0xFFE040FB); // roxo

  // Gradientes
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
  );

  static const gradientRun = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
  );

  static const gradientXp = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
  );

  static const gradientSteps = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF448AFF), Color(0xFF7C4DFF)],
  );

  static const gradientWorkout = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
  );
}

// ─────────────────────────────────────────────
//  TEMA PRINCIPAL
// ─────────────────────────────────────────────
class AppRadii {
  AppRadii._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.black,
        secondary: AppColors.accent1,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        error: Color(0xFFCF6679),
      ),

      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      // ── AppBar ──────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── BottomNavigationBar ──────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Cards ───────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withAlpha(28),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textHint,
            size: selected ? 24 : 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.primary : AppColors.textHint,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textHint,
          size: 22,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: AppColors.primary.withAlpha(28),
        useIndicator: true,
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // ── ElevatedButton ───────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ───────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextButton ───────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── InputDecoration ──────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),

      // ── ProgressIndicator ────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.textHint,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minVerticalPadding: 10,
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFF2A2A2A),
        linearMinHeight: 8,
      ),

      // ── Divider ──────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 1,
        space: 1,
      ),

      // ── TextTheme ────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -1.0,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS REUTILIZÁVEIS DE TEMA
// ─────────────────────────────────────────────

/// Card com gradiente e borda sutil
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const AppGradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.gradientCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(58),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Barra de progresso XP customizada
class AppXpBar extends StatelessWidget {
  final int xp;
  final int maxXp;

  const AppXpBar({super.key, required this.xp, this.maxXp = 100});

  @override
  Widget build(BuildContext context) {
    final progress = (xp / maxXp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('XP', style: Theme.of(context).textTheme.labelLarge),
            Text(
              '$xp / $maxXp',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF2A2A2A)),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradientXp),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip de stat (label + valor)
class AppStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const AppStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Seção com título e padding padrão
class AppSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool dark;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dark ? Colors.black.withAlpha(35) : chipColor.withAlpha(28),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: dark ? Colors.white.withAlpha(35) : chipColor.withAlpha(90),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: dark ? Colors.white : chipColor),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark ? Colors.white : chipColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLoadingCard extends StatelessWidget {
  final String message;
  final LinearGradient? gradient;

  const AppLoadingCard({super.key, required this.message, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: AppGradientCard(
        gradient: gradient,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(24),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const _AppSkeletonLine(widthFactor: 0.78),
                  const SizedBox(height: 7),
                  const _AppSkeletonLine(widthFactor: 0.48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.98, end: 1),
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: AppGradientCard(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.primary.withAlpha(70)),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                if (action != null) ...[const SizedBox(height: 18), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppSkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _AppSkeletonLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.9),
      duration: AppMotion.slow,
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),
    );
  }
}
