import 'package:flutter/material.dart';

import '../../models/corrida_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class HistoricoCorridasPage extends StatefulWidget {
  const HistoricoCorridasPage({super.key});

  @override
  State<HistoricoCorridasPage> createState() => _HistoricoCorridasPageState();
}

class _HistoricoCorridasPageState extends State<HistoricoCorridasPage> {
  List<_CorridaHistoricoItem> _corridas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCorridas();
  }

  Future<void> _carregarCorridas() async {
    final corridas = await StorageService.carregarCorridas();
    final itens = <_CorridaHistoricoItem>[];

    for (var i = 0; i < corridas.length; i++) {
      itens.add(_CorridaHistoricoItem(indexOriginal: i, corrida: corridas[i]));
    }

    if (!mounted) return;

    setState(() {
      _corridas = itens.reversed.toList();
      _carregando = false;
    });
  }

  Future<void> _confirmarExclusao(_CorridaHistoricoItem item) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir corrida?'),
          content: const Text(
            'Essa corrida sera removida do historico e dos totais salvos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    await StorageService.removerCorrida(item.indexOriginal);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Corrida excluida')));

    await _carregarCorridas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: _carregando
                ? const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _corridas.isEmpty
                ? SliverToBoxAdapter(child: _buildEstadoVazio(context))
                : SliverList.builder(
                    itemCount: _corridas.length,
                    itemBuilder: (context, index) {
                      final item = _corridas[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _corridas.length - 1 ? 0 : 14,
                        ),
                        child: _CorridaCard(
                          corrida: item.corrida,
                          onExcluir: () => _confirmarExclusao(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        22,
      ),
      child: AppPremiumHeader(
        eyebrow: 'Atividades',
        title: 'Historico de corridas',
        subtitle: 'Revise distancia, tempo, ritmo, velocidade e calorias.',
        icon: Icons.directions_run_rounded,
        gradient: AppColors.gradientRun,
        trailing: AppIconActionButton(
          icon: Icons.close_rounded,
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context) {
    return AppGradientCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.gradientRun,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: Colors.black,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma corrida salva',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Finalize uma corrida na aba Atividades para preencher seu historico.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorridaCard extends StatelessWidget {
  final CorridaModel corrida;
  final VoidCallback onExcluir;

  const _CorridaCard({required this.corrida, required this.onExcluir});

  double get _velocidadeMedia {
    if (corrida.averageSpeed > 0) return corrida.averageSpeed;
    if (corrida.segundos <= 0) return 0;

    return corrida.distancia / (corrida.segundos / 3600);
  }

  double get _calorias {
    if (corrida.calories > 0) return corrida.calories;

    return corrida.distancia * 60;
  }

  String get _tempo {
    final h = corrida.segundos ~/ 3600;
    final m = (corrida.segundos % 3600) ~/ 60;
    final s = corrida.segundos % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String get _ritmo {
    if (corrida.pace > 0) {
      final totalSeconds = (corrida.pace * 60).round();
      final minutos = totalSeconds ~/ 60;
      final segundos = totalSeconds % 60;

      return '$minutos:${segundos.toString().padLeft(2, '0')} min/km';
    }

    if (corrida.distancia <= 0 || corrida.segundos <= 0) return '--';

    final segundosPorKm = (corrida.segundos / corrida.distancia).round();
    final minutos = segundosPorKm ~/ 60;
    final segundos = segundosPorKm % 60;

    return '$minutos:${segundos.toString().padLeft(2, '0')} min/km';
  }

  String get _dataFormatada {
    final data = DateTime.tryParse(corrida.data);
    if (data == null) return corrida.data;

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano as $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientRun,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${corrida.distancia.toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dataFormatada,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir corrida',
                onPressed: onExcluir,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFCF6679),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RunMetric(
                icon: Icons.timer_rounded,
                label: 'Tempo',
                value: _tempo,
              ),
              _RunMetric(
                icon: Icons.speed_rounded,
                label: 'Vel. media',
                value: '${_velocidadeMedia.toStringAsFixed(1)} km/h',
              ),
              _RunMetric(
                icon: Icons.route_rounded,
                label: 'Ritmo',
                value: _ritmo,
              ),
              _RunMetric(
                icon: Icons.local_fire_department_rounded,
                label: 'Calorias',
                value: '${_calorias.toStringAsFixed(0)} kcal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RunMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withAlpha(14)),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CorridaHistoricoItem {
  final int indexOriginal;
  final CorridaModel corrida;

  const _CorridaHistoricoItem({
    required this.indexOriginal,
    required this.corrida,
  });
}
