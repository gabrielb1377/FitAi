import 'package:flutter/material.dart';
import 'dart:async';

import '../core/app_router.dart';
import '../core/app_shell.dart';
import '../services/storage_service.dart';
import '../models/corrida_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  String nome = "Gabriel";
  String peso = "70 kg";
  String altura = "175 cm";
  String idade = "18";

  int passos = 7542;
  int metaPassos = 10000;

  int segundos = 0;
  double distancia = 0.0;
  double velocidadeMedia = 0.0;

  int xp = 0;
  int nivel = 1;

  double distanciaTotal = 0;
  int tempoTotal = 0;
  int totalCorridas = 0;

  int streak = 1;
  int melhorStreak = 1;

  bool conquistaPrimeiraCorrida = false;
  bool conquista10Km = false;

  Timer? timer;
  bool corridaIniciada = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
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
          content: Text("🏆 Conquista desbloqueada: Primeira Corrida"),
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
              content: Text("🏆 Conquista desbloqueada: 10 KM Percorridos"),
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

    // Atualiza estatísticas gerais
    distanciaTotal += distancia;
    tempoTotal += segundos;
    totalCorridas++;

    await StorageService.salvarDistanciaTotal(distanciaTotal);
    await StorageService.salvarTempoTotal(tempoTotal);
    await StorageService.salvarTotalCorridas(totalCorridas);

    // Salva a corrida no histórico
    if (distancia > 0) {
      await StorageService.salvarCorrida(
        CorridaModel(
          distancia: distancia,
          segundos: segundos,
          data: DateTime.now().toString(),
        ),
      );
    }

    // Zera a corrida atual
    setState(() {
      distancia = 0;
      segundos = 0;
      velocidadeMedia = 0;
    });

    // Salva os valores zerados da corrida atual
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
        SnackBar(content: Text("🎉 Você subiu para o nível $nivel!")),
      );
    }
  }

  String rankAtual() {
    if (nivel >= 50) return "💎 Diamante";
    if (nivel >= 30) return "🏆 Platina";
    if (nivel >= 20) return "🥇 Ouro";
    if (nivel >= 10) return "🥈 Prata";

    return "🥉 Bronze";
  }

  String objetivoDoDia() {
    if (distancia >= 5) {
      return "Excelente! Você já correu mais de 5 km.";
    }

    if (segundos > 600) {
      return "Ótimo ritmo! Continue assim.";
    }

    return "Que tal iniciar uma corrida hoje?";
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

    return AppShell(
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
