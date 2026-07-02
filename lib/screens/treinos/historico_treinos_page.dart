import 'package:flutter/material.dart';

import '../../models/historico_treino_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class HistoricoTreinosPage extends StatefulWidget {
  const HistoricoTreinosPage({super.key});

  @override
  State<HistoricoTreinosPage> createState() => _HistoricoTreinosPageState();
}

class _HistoricoTreinosPageState extends State<HistoricoTreinosPage> {
  late Future<List<HistoricoTreinoModel>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _historicoFuture = StorageService.carregarHistoricoTreinos();
  }

  Future<void> _recarregar() async {
    final future = StorageService.carregarHistoricoTreinos();

    setState(() {
      _historicoFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Histórico de treinos")),
      body: FutureBuilder<List<HistoricoTreinoModel>>(
        future: _historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: "Carregando historico..."),
            );
          }

          if (snapshot.hasError) {
            return _estadoMensagem(
              icon: Icons.error_outline_rounded,
              titulo: "Não foi possível carregar",
              subtitulo: "Puxe para atualizar e tente novamente.",
            );
          }

          final historico = snapshot.data ?? [];

          if (historico.isEmpty) {
            return _estadoMensagem(
              icon: Icons.history_rounded,
              titulo: "Nenhum treino finalizado ainda",
              subtitulo: "Quando você concluir um treino, ele aparecerá aqui.",
            );
          }

          final grupos = _agruparPorData(historico);

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                20,
                _horizontalPadding(context),
                32,
              ),
              children: [
                _resumoTopo(historico),
                const SizedBox(height: 22),
                for (final grupo in grupos.entries) ...[
                  _grupoTitulo(grupo.key, grupo.value.length),
                  const SizedBox(height: 10),
                  for (final item in grupo.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _historicoCard(item),
                    ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _estadoMensagem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          120,
          _horizontalPadding(context),
          32,
        ),
        children: [
          AppEmptyState(icon: icon, title: titulo, message: subtitulo),
        ],
      ),
    );
  }

  Widget _resumoTopo(List<HistoricoTreinoModel> historico) {
    final tempoTotal = historico.fold<int>(
      0,
      (total, item) => total + item.tempoSegundos,
    );
    final xpTotal = historico.fold<int>(
      0,
      (total, item) => total + item.xpGanho,
    );
    final caloriasTotal = historico.fold<int>(
      0,
      (total, item) => total + item.caloriasEstimadas,
    );

    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RESUMO DO HISTORICO",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Treinos finalizados",
            style: TextStyle(
              color: Colors.black,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _resumoPill(
                icon: Icons.fitness_center_rounded,
                label: "Treinos",
                value: "${historico.length}",
              ),
              _resumoPill(
                icon: Icons.timer_rounded,
                label: "Tempo",
                value: _formatarTempoResumo(tempoTotal),
              ),
              _resumoPill(
                icon: Icons.bolt_rounded,
                label: "XP",
                value: "+$xpTotal",
              ),
              _resumoPill(
                icon: Icons.local_fire_department_rounded,
                label: "Calorias",
                value: "$caloriasTotal kcal",
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  Widget _resumoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 134,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 18),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupoTitulo(String chave, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _formatarDataGrupo(chave),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "$total treino${total == 1 ? '' : 's'}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<HistoricoTreinoModel>> _agruparPorData(
    List<HistoricoTreinoModel> historico,
  ) {
    final grupos = <String, List<HistoricoTreinoModel>>{};

    for (final item in historico) {
      final chave = _chaveData(item.dataHora);
      grupos.putIfAbsent(chave, () => <HistoricoTreinoModel>[]).add(item);
    }

    return grupos;
  }

  Widget _historicoCard(HistoricoTreinoModel historico) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historico.nomeTreino,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatarData(historico.dataHora),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _xpPill(historico.xpGanho),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(historico.objetivo),
              _metaChip(historico.nivel),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statBox(
                icon: Icons.timer_rounded,
                label: "Tempo",
                value: historico.tempoFormatado,
              ),
              _statBox(
                icon: Icons.check_circle_rounded,
                label: "Exercícios",
                value:
                    "${historico.exerciciosConcluidos}/${historico.exerciciosTotais}",
              ),
              _statBox(
                icon: Icons.local_fire_department_rounded,
                label: "Calorias",
                value: "${historico.caloriasEstimadas} kcal",
              ),
              _statBox(
                icon: Icons.bolt_rounded,
                label: "XP",
                value: "+${historico.xpGanho}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _xpPill(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withAlpha(90)),
      ),
      child: Text(
        "+$xp XP",
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metaChip(String texto) {
    final label = texto.trim().isEmpty ? "Geral" : texto.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return SizedBox(
      width: 132,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    if (data.millisecondsSinceEpoch == 0) {
      return "Data indisponível";
    }

    final local = data.toLocal();

    return "${_doisDigitos(local.day)}/${_doisDigitos(local.month)}/${local.year} "
        "${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}";
  }

  String _formatarDataGrupo(String chave) {
    final data = _dataDaChave(chave);
    final hoje = _somenteData(DateTime.now());
    final ontem = hoje.subtract(const Duration(days: 1));

    if (data == hoje) return "Hoje";
    if (data == ontem) return "Ontem";

    return "${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}";
  }

  String _formatarTempoResumo(int segundos) {
    if (segundos <= 0) return "0 min";

    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas > 0) {
      return "${horas}h ${minutos}min";
    }

    return "${minutos}min";
  }

  String _chaveData(DateTime data) {
    final local = data.toLocal();
    return "${local.year}-${_doisDigitos(local.month)}-${_doisDigitos(local.day)}";
  }

  DateTime _dataDaChave(String chave) {
    final partes = chave.split("-");
    if (partes.length != 3) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime(
      int.tryParse(partes[0]) ?? 0,
      int.tryParse(partes[1]) ?? 1,
      int.tryParse(partes[2]) ?? 1,
    );
  }

  DateTime _somenteData(DateTime data) {
    final local = data.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _doisDigitos(int valor) {
    return valor.toString().padLeft(2, "0");
  }
}
