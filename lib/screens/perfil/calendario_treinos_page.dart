import 'package:flutter/material.dart';

import '../../models/historico_treino_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class CalendarioTreinosPage extends StatefulWidget {
  const CalendarioTreinosPage({super.key});

  @override
  State<CalendarioTreinosPage> createState() => _CalendarioTreinosPageState();
}

class _CalendarioTreinosPageState extends State<CalendarioTreinosPage> {
  late Future<List<HistoricoTreinoModel>> _historicoFuture;
  late DateTime mesAtual;
  DateTime? diaSelecionado;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    mesAtual = DateTime(hoje.year, hoje.month);
    diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day);
    _historicoFuture = StorageService.carregarHistoricoTreinos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Calendário de Treinos")),
      body: FutureBuilder<List<HistoricoTreinoModel>>(
        future: _historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: "Carregando calendário..."),
            );
          }

          final historico = snapshot.data ?? const <HistoricoTreinoModel>[];

          if (historico.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppEmptyState(
                icon: Icons.calendar_month_rounded,
                title:
                    "Complete seu primeiro treino para preencher o calendário.",
                message:
                    "Seus treinos concluídos vão aparecer aqui por dia e por mês.",
              ),
            );
          }

          final treinosPorDia = _agruparPorDia(historico);
          final selecionados = _treinosDoDia(treinosPorDia, diaSelecionado);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              20,
              _horizontalPadding(context),
              32,
            ),
            children: [
              _cabecalhoMes(),
              const SizedBox(height: 16),
              _legenda(),
              const SizedBox(height: 12),
              _calendario(treinosPorDia),
              const SizedBox(height: 20),
              _detalheDia(selecionados),
            ],
          );
        },
      ),
    );
  }

  Widget _cabecalhoMes() {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Row(
        children: [
          _navButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _mudarMes(-1),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  "CALENDÁRIO DE TREINOS",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_nomeMes(mesAtual.month)} ${mesAtual.year}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _navButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _mudarMes(1),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(24),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _legenda() {
    return AppGradientCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          _LegendaItem(color: AppColors.primary, label: "Treino concluído"),
          _LegendaItem(color: AppColors.accent1, label: "Dia atual"),
          _LegendaItem(color: AppColors.surfaceVariant, label: "Sem treino"),
        ],
      ),
    );
  }

  Widget _calendario(Map<String, List<HistoricoTreinoModel>> treinosPorDia) {
    final dias = _diasDoMes();

    return AppGradientCard(
      child: Column(
        children: [
          Row(
            children: const [
              _SemanaLabel("Seg"),
              _SemanaLabel("Ter"),
              _SemanaLabel("Qua"),
              _SemanaLabel("Qui"),
              _SemanaLabel("Sex"),
              _SemanaLabel("Sáb"),
              _SemanaLabel("Dom"),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dias.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final dia = dias[index];

              if (dia == null) return const SizedBox.shrink();

              final chave = _chaveData(dia);
              final treinos = treinosPorDia[chave] ?? const [];
              final temTreino = treinos.isNotEmpty;
              final hoje = _mesmoDia(dia, DateTime.now());
              final selecionado =
                  diaSelecionado != null && _mesmoDia(dia, diaSelecionado!);

              return _DiaCalendario(
                dia: dia.day,
                temTreino: temTreino,
                hoje: hoje,
                selecionado: selecionado,
                totalTreinos: treinos.length,
                onTap: temTreino
                    ? () {
                        setState(() {
                          diaSelecionado = dia;
                        });
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detalheDia(List<HistoricoTreinoModel> treinos) {
    final data = diaSelecionado;

    if (data == null || treinos.isEmpty) {
      return AppGradientCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data == null
                    ? "Selecione um dia com treino."
                    : "Nenhum treino registrado em ${_formatarData(data)}.",
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final tempo = treinos.fold<int>(
      0,
      (total, treino) => total + treino.tempoSegundos,
    );
    final volume = treinos.fold<double>(
      0,
      (total, treino) => total + treino.volumeTotal,
    );
    final series = treinos.fold<int>(
      0,
      (total, treino) => total + treino.seriesConcluidas,
    );
    final xp = treinos.fold<int>(0, (total, treino) => total + treino.xpGanho);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatarData(data),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        AppGradientCard(
          child: Column(
            children: [
              _infoRow(
                Icons.fitness_center_rounded,
                "Treinos",
                "${treinos.length}",
              ),
              _infoRow(
                Icons.timer_rounded,
                "Tempo total",
                _formatarDuracao(tempo),
              ),
              _infoRow(
                Icons.monitor_weight_rounded,
                "Volume total",
                _formatarPeso(volume),
              ),
              _infoRow(Icons.format_list_numbered_rounded, "Séries", "$series"),
              _infoRow(Icons.bolt_rounded, "XP ganho", "+$xp", isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final treino in treinos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _treinoCard(treino),
          ),
      ],
    );
  }

  Widget _treinoCard(HistoricoTreinoModel treino) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treino.nomeTreino,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.timer_rounded, treino.tempoFormatado),
              _chip(
                Icons.check_circle_rounded,
                "${treino.exerciciosConcluidos}/${treino.exerciciosTotais} exercícios",
              ),
              _chip(
                Icons.format_list_numbered_rounded,
                "${treino.seriesConcluidas} séries",
              ),
              _chip(
                Icons.monitor_weight_rounded,
                _formatarPeso(treino.volumeTotal),
              ),
              _chip(Icons.bolt_rounded, "+${treino.xpGanho} XP"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _mudarMes(int delta) {
    setState(() {
      mesAtual = DateTime(mesAtual.year, mesAtual.month + delta);
      diaSelecionado = DateTime(mesAtual.year, mesAtual.month);
    });
  }

  List<DateTime?> _diasDoMes() {
    final primeiroDia = DateTime(mesAtual.year, mesAtual.month);
    final totalDias = DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
    final deslocamento = primeiroDia.weekday - DateTime.monday;
    final dias = <DateTime?>[
      for (var index = 0; index < deslocamento; index++) null,
      for (var dia = 1; dia <= totalDias; dia++)
        DateTime(mesAtual.year, mesAtual.month, dia),
    ];

    while (dias.length % 7 != 0) {
      dias.add(null);
    }

    return dias;
  }

  Map<String, List<HistoricoTreinoModel>> _agruparPorDia(
    List<HistoricoTreinoModel> historico,
  ) {
    final grupos = <String, List<HistoricoTreinoModel>>{};

    for (final treino in historico) {
      final chave = _chaveData(treino.dataHora);
      grupos.putIfAbsent(chave, () => <HistoricoTreinoModel>[]).add(treino);
    }

    for (final grupo in grupos.values) {
      grupo.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    }

    return grupos;
  }

  List<HistoricoTreinoModel> _treinosDoDia(
    Map<String, List<HistoricoTreinoModel>> treinosPorDia,
    DateTime? dia,
  ) {
    if (dia == null) return const [];
    return treinosPorDia[_chaveData(dia)] ?? const [];
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _chaveData(DateTime data) {
    final local = data.toLocal();
    return "${local.year}-${local.month}-${local.day}";
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, "0");
    final mes = data.month.toString().padLeft(2, "0");
    return "$dia/$mes/${data.year}";
  }

  String _formatarDuracao(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas <= 0) return "${minutos}min";
    if (minutos <= 0) return "${horas}h";

    return "${horas}h ${minutos}min";
  }

  String _formatarPeso(double peso) {
    if (peso >= 1000) return "${_formatarNumero(peso / 1000)} t";
    return "${_formatarNumero(peso)} kg";
  }

  String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll(".", ",");
  }

  String _nomeMes(int mes) {
    const nomes = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];

    return nomes[(mes - 1).clamp(0, 11)];
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _DiaCalendario extends StatelessWidget {
  final int dia;
  final bool temTreino;
  final bool hoje;
  final bool selecionado;
  final int totalTreinos;
  final VoidCallback? onTap;

  const _DiaCalendario({
    required this.dia,
    required this.temTreino,
    required this.hoje,
    required this.selecionado,
    required this.totalTreinos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selecionado
        ? AppColors.primary
        : hoje
        ? AppColors.accent1
        : const Color(0xFF2A2A2A);
    final background = temTreino
        ? AppColors.primary.withAlpha(28)
        : AppColors.surfaceVariant;
    final textColor = temTreino ? Colors.white : Colors.white54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selecionado ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$dia",
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: temTreino
                      ? AppColors.primary
                      : hoje
                      ? AppColors.accent1
                      : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
              if (totalTreinos > 1) ...[
                const SizedBox(height: 3),
                Text(
                  "$totalTreinos",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SemanaLabel extends StatelessWidget {
  final String label;

  const _SemanaLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
