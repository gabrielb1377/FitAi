import 'package:flutter/material.dart';

import '../screens/atividades_page.dart';
import '../screens/exercicios/biblioteca_exercicios_page.dart';
import '../screens/home/home_page.dart';
import '../screens/perfil/perfil_page.dart';
import '../screens/treinos/treinos_page.dart';

class AppRouteDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppRouteDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AppRouteState {
  final String nome;
  final String peso;
  final String altura;
  final String idade;
  final int passos;
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final int xp;
  final int nivel;
  final bool corridaIniciada;
  final bool conquistaPrimeiraCorrida;
  final bool conquista10Km;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;
  final Future<void> Function() carregarDados;

  const AppRouteState({
    required this.nome,
    required this.peso,
    required this.altura,
    required this.idade,
    required this.passos,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.xp,
    required this.nivel,
    required this.corridaIniciada,
    required this.conquistaPrimeiraCorrida,
    required this.conquista10Km,
    required this.iniciarCorrida,
    required this.pararCorrida,
    required this.carregarDados,
  });
}

class AppRouter {
  const AppRouter._();

  static const destinations = <AppRouteDestination>[
    AppRouteDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppRouteDestination(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      label: 'Planos',
    ),
    AppRouteDestination(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Biblioteca',
    ),
    AppRouteDestination(
      icon: Icons.directions_run_outlined,
      selectedIcon: Icons.directions_run_rounded,
      label: 'Atividades',
    ),
    AppRouteDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  static List<Widget> buildPages(AppRouteState state) {
    return [
      HomePage(
        key: const PageStorageKey('tab-home'),
        nome: state.nome,
        distancia: state.distancia,
        passos: state.passos,
        xp: state.xp,
        nivel: state.nivel,
        onXpAtualizado: state.carregarDados,
      ),
      TreinosPage(
        key: const PageStorageKey('tab-planos'),
        onXpAtualizado: state.carregarDados,
      ),
      const BibliotecaExerciciosPage(key: PageStorageKey('tab-biblioteca')),
      AtividadesPage(
        key: const PageStorageKey('tab-atividades'),
        passos: state.passos,
        distancia: state.distancia,
        velocidadeMedia: state.velocidadeMedia,
        segundos: state.segundos,
        corridaIniciada: state.corridaIniciada,
        iniciarCorrida: state.iniciarCorrida,
        pararCorrida: state.pararCorrida,
      ),
      PerfilPage(
        key: const PageStorageKey('tab-perfil'),
        nome: state.nome,
        peso: state.peso,
        altura: state.altura,
        idade: state.idade,
        nivel: state.nivel,
        conquistaPrimeiraCorrida: state.conquistaPrimeiraCorrida,
        conquista10Km: state.conquista10Km,
        onPerfilAtualizado: state.carregarDados,
      ),
    ];
  }
}
