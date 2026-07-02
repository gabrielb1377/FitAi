import 'dart:async';

import 'package:flutter/material.dart';

import '../models/corrida_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_router.dart';
import 'navigation/bottom_navigation.dart';
import 'navigation/side_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  String nome = "Gabriel";
  String peso = "70 kg";
  String altura = "175 cm";
  String idade = "18";

  int passos = 7542;

  int segundos = 0;
  double distancia = 0.0;
  double velocidadeMedia = 0.0;

  int xp = 0;
  int nivel = 1;

  double distanciaTotal = 0;
  int tempoTotal = 0;
  int totalCorridas = 0;

  bool conquistaPrimeiraCorrida = false;
  bool conquista10Km = false;

  Timer? timer;
  bool corridaIniciada = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> carregarDados() async {
    xp = await StorageService.carregarXp();
    nivel = await StorageService.carregarNivel();

    final perfil = await StorageService.carregarPerfilUsuario();

    nome = perfil['nome'] ?? nome;
    peso = perfil['peso'] ?? peso;
    altura = perfil['altura'] ?? altura;
    idade = perfil['idade'] ?? idade;

    distanciaTotal = await StorageService.carregarDistanciaTotal();
    tempoTotal = await StorageService.carregarTempoTotal();
    totalCorridas = await StorageService.carregarTotalCorridas();

    distancia = await StorageService.carregarDistancia();
    segundos = await StorageService.carregarSegundos();
    passos = await StorageService.carregarPassos();

    debugPrint("Distancia carregada: $distancia");
    debugPrint("Segundos carregados: $segundos");
    debugPrint("Passos carregados: $passos");

    conquistaPrimeiraCorrida = await StorageService.carregarPrimeiraCorrida();
    conquista10Km = await StorageService.carregar10Km();

    if (segundos > 0) {
      velocidadeMedia = distancia / (segundos / 3600);
    }

    debugPrint("Primeira corrida: $conquistaPrimeiraCorrida");
    debugPrint("Conquista 10km: $conquista10Km");
    debugPrint("Dashboard carregou XP: $xp");
    debugPrint("Dashboard carregou Nivel: $nivel");

    if (!mounted) return;
    setState(() {});
  }

  void iniciarCorrida() {
    if (corridaIniciada) return;

    corridaIniciada = true;

    if (!conquistaPrimeiraCorrida) {
      conquistaPrimeiraCorrida = true;
      StorageService.salvarPrimeiraCorrida(true);

      debugPrint("SALVOU PRIMEIRA CORRIDA");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ðŸ† Conquista desbloqueada: Primeira Corrida"),
        ),
      );

      xp += 20;
      StorageService.salvarXp(xp);
    }

    setState(() {
      xp += 10;
    });

    StorageService.salvarXp(xp);
    verificarNivel();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        segundos++;

        StorageService.salvarSegundos(segundos);

        if (segundos % 60 == 0) {
          xp += 5;
          StorageService.salvarXp(xp);
          verificarNivel();
        }

        distancia += 0.01;

        StorageService.salvarPassos(passos);
        StorageService.salvarDistancia(distancia);

        if (distancia >= 10 && !conquista10Km) {
          conquista10Km = true;
          StorageService.salvar10Km(true);

          xp += 100;
          StorageService.salvarXp(xp);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ðŸ† Conquista desbloqueada: 10 KM Percorridos"),
            ),
          );

          verificarNivel();
        }

        if (segundos > 0) {
          velocidadeMedia = distancia / (segundos / 3600);
        }
      });
    });
  }

  Future<void> pararCorrida() async {
    timer?.cancel();

    corridaIniciada = false;

    distanciaTotal += distancia;
    tempoTotal += segundos;
    totalCorridas++;

    await StorageService.salvarDistanciaTotal(distanciaTotal);
    await StorageService.salvarTempoTotal(tempoTotal);
    await StorageService.salvarTotalCorridas(totalCorridas);

    if (distancia > 0) {
      await StorageService.salvarCorrida(
        CorridaModel(
          distancia: distancia,
          segundos: segundos,
          data: DateTime.now().toString(),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      distancia = 0;
      segundos = 0;
      velocidadeMedia = 0;
    });

    await StorageService.salvarDistancia(0);
    await StorageService.salvarSegundos(0);
  }

  Future<void> verificarNivel() async {
    if (xp >= 100) {
      nivel++;
      xp -= 100;

      await StorageService.salvarNivel(nivel);
      await StorageService.salvarXp(xp);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ðŸŽ‰ VocÃª subiu para o nÃ­vel $nivel!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeState = AppRouteState(
      nome: nome,
      peso: peso,
      altura: altura,
      idade: idade,
      passos: passos,
      distancia: distancia,
      velocidadeMedia: velocidadeMedia,
      segundos: segundos,
      xp: xp,
      nivel: nivel,
      corridaIniciada: corridaIniciada,
      conquistaPrimeiraCorrida: conquistaPrimeiraCorrida,
      conquista10Km: conquista10Km,
      iniciarCorrida: iniciarCorrida,
      pararCorrida: pararCorrida,
      carregarDados: carregarDados,
    );
    final pages = AppRouter.buildPages(routeState);

    return AppNavigationFrame(
      selectedIndex: currentIndex,
      pages: pages,
      destinations: AppRouter.destinations,
      onDestinationSelected: (index) {
        if (index >= pages.length) return;

        setState(() {
          currentIndex = index;
        });
      },
    );
  }
}

class AppNavigationFrame extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppRouteDestination> destinations;
  final List<Widget> pages;

  const AppNavigationFrame({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  @override
  State<AppNavigationFrame> createState() => _AppNavigationFrameState();
}

class _AppNavigationFrameState extends State<AppNavigationFrame> {
  int previousIndex = 0;

  @override
  void didUpdateWidget(covariant AppNavigationFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      previousIndex = oldWidget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.selectedIndex.clamp(0, widget.pages.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 840;
        final page = _AnimatedShellPage(
          index: index,
          previousIndex: previousIndex,
          child: widget.pages[index],
        );

        if (useSideNavigation) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AppSideNavigation(
                  selectedIndex: index,
                  destinations: widget.destinations,
                  onDestinationSelected: widget.onDestinationSelected,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: page,
          bottomNavigationBar: AppBottomNavigation(
            selectedIndex: index,
            destinations: widget.destinations,
            onDestinationSelected: widget.onDestinationSelected,
          ),
        );
      },
    );
  }
}

class _AnimatedShellPage extends StatelessWidget {
  final int index;
  final int previousIndex;
  final Widget child;

  const _AnimatedShellPage({
    required this.index,
    required this.previousIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final forward = index >= previousIndex;

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: Offset(forward ? 0.035 : -0.035, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: child),
    );
  }
}
