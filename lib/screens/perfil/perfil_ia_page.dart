import 'package:flutter/material.dart';

import '../../models/fitai_memory_model.dart';
import '../../services/fitai_memory_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class PerfilIAPage extends StatefulWidget {
  final String nome;
  final String idade;
  final String peso;
  final String altura;

  const PerfilIAPage({
    super.key,
    this.nome = '',
    this.idade = '',
    this.peso = '',
    this.altura = '',
  });

  @override
  State<PerfilIAPage> createState() => _PerfilIAPageState();
}

class _PerfilIAPageState extends State<PerfilIAPage> {
  final _memoryService = const FitAIMemoryService();

  final _objetivoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _localTreinoController = TextEditingController();
  final _equipamentosController = TextEditingController();
  final _lesoesController = TextEditingController();
  final _tempoMedioController = TextEditingController();
  final _horarioController = TextEditingController();

  FitAIMemoryModel _memoria = const FitAIMemoryModel();
  String _resumo = '';
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarMemoria();
  }

  @override
  void dispose() {
    _objetivoController.dispose();
    _pesoController.dispose();
    _localTreinoController.dispose();
    _equipamentosController.dispose();
    _lesoesController.dispose();
    _tempoMedioController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  Future<void> _carregarMemoria() async {
    final salva = await _memoryService.carregarMemoria();
    final memoria = salva.estaVazia ? _memoriaComDadosDoPerfil(salva) : salva;
    final resumo = await _memoryService.gerarResumoParaIA(memoria: memoria);

    if (!mounted) return;

    setState(() {
      _memoria = memoria;
      _resumo = resumo;
      _carregando = false;
    });

    _preencherControllers(memoria);
  }

  FitAIMemoryModel _memoriaComDadosDoPerfil(FitAIMemoryModel memoria) {
    return memoria.copyWith(
      nome: widget.nome,
      idade: _parseInt(widget.idade),
      peso: _parseDouble(widget.peso),
      altura: _parseDouble(widget.altura),
    );
  }

  void _preencherControllers(FitAIMemoryModel memoria) {
    _objetivoController.text = memoria.objetivo;
    _pesoController.text = memoria.peso > 0
        ? _formatarNumero(memoria.peso)
        : '';
    _localTreinoController.text = memoria.localTreino;
    _equipamentosController.text = memoria.equipamentos.join(', ');
    _lesoesController.text = memoria.lesoes.join(', ');
    _tempoMedioController.text = memoria.tempoMedioTreino > 0
        ? '${memoria.tempoMedioTreino}'
        : '';
    _horarioController.text = memoria.horarioPreferido;
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
    });

    final atualizada = _memoria.copyWith(
      objetivo: _objetivoController.text.trim(),
      peso: _parseDouble(_pesoController.text),
      localTreino: _localTreinoController.text.trim(),
      equipamentos: _parseLista(_equipamentosController.text),
      lesoes: _parseLista(_lesoesController.text),
      tempoMedioTreino: _parseInt(_tempoMedioController.text),
      horarioPreferido: _horarioController.text.trim(),
    );

    await _memoryService.salvarMemoria(atualizada);
    final resumo = await _memoryService.gerarResumoParaIA(memoria: atualizada);

    if (!mounted) return;

    setState(() {
      _memoria = atualizada;
      _resumo = resumo;
      _salvando = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil IA salvo')));
  }

  Future<void> _limpar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Limpar memoria da IA?'),
          content: const Text(
            'As preferencias salvas para a IA serao apagadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    await _memoryService.limparMemoria();
    final memoria = _memoriaComDadosDoPerfil(const FitAIMemoryModel());
    final resumo = await _memoryService.gerarResumoParaIA(memoria: memoria);

    if (!mounted) return;

    setState(() {
      _memoria = memoria;
      _resumo = resumo;
    });

    _preencherControllers(memoria);
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
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              32,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                if (_carregando)
                  const AppLoading(message: 'Carregando Perfil IA...')
                else ...[
                  _buildResumoCard(context),
                  const SizedBox(height: 18),
                  _buildFormCard(context),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.primary(
                          label: 'Salvar Perfil IA',
                          icon: Icons.check_rounded,
                          loading: _salvando,
                          onPressed: _salvando ? null : _salvar,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.danger(
                          label: 'Limpar',
                          icon: Icons.delete_outline_rounded,
                          onPressed: _salvando ? null : _limpar,
                        ),
                      ),
                    ],
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        MediaQuery.of(context).padding.top + 16,
        _horizontalPadding(context),
        22,
      ),
      child: AppPremiumHeader(
        eyebrow: 'FITAI Memory',
        title: 'Meu Perfil IA',
        subtitle: 'Controle o que a IA sabe sobre voce.',
        icon: Icons.psychology_rounded,
        gradient: AppColors.gradientPrimary,
        trailing: AppIconActionButton(
          icon: Icons.close_rounded,
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildResumoCard(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que a IA sabe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            _resumo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar memoria',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          _MemoryTextField(
            controller: _objetivoController,
            label: 'Objetivo',
            hint: 'Ex: hipertrofia, emagrecimento, corrida',
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _pesoController,
            label: 'Peso',
            hint: 'Ex: 70',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _localTreinoController,
            label: 'Local de treino',
            hint: 'Ex: casa, academia, parque',
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _equipamentosController,
            label: 'Equipamentos',
            hint: 'Separe por virgula',
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _lesoesController,
            label: 'Lesoes ou limitacoes',
            hint: 'Separe por virgula',
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _tempoMedioController,
            label: 'Tempo medio de treino',
            hint: 'Minutos',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _MemoryTextField(
            controller: _horarioController,
            label: 'Horario preferido',
            hint: 'Ex: manha, noite, 18h',
          ),
        ],
      ),
    );
  }

  List<String> _parseLista(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  double _parseDouble(String value) {
    final normalizado = value
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalizado) ?? 0;
  }

  String _formatarNumero(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _MemoryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _MemoryTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
