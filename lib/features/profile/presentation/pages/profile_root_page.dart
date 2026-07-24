import 'package:flutter/material.dart';

import '../../../../screens/perfil/perfil_page.dart';

/// Adapter incremental para a raiz atual do Perfil.
class ProfileRootPage extends StatelessWidget {
  const ProfileRootPage({
    super.key,
    required this.name,
    required this.weight,
    required this.height,
    required this.age,
    required this.level,
    required this.firstRunAchievement,
    required this.tenKilometersAchievement,
    this.onProfileUpdated,
  });

  final String name;
  final String weight;
  final String height;
  final String age;
  final int level;
  final bool firstRunAchievement;
  final bool tenKilometersAchievement;
  final Future<void> Function()? onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    return PerfilPage(
      nome: name,
      peso: weight,
      altura: height,
      idade: age,
      nivel: level,
      conquistaPrimeiraCorrida: firstRunAchievement,
      conquista10Km: tenKilometersAchievement,
      onPerfilAtualizado: onProfileUpdated,
    );
  }
}
