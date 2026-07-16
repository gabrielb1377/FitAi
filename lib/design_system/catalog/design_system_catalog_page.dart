import 'package:flutter/material.dart';

import '../components/components.dart';
import '../tokens/fit_icons.dart';
import '../tokens/fit_spacing.dart';
import '../theme/fit_theme.dart';

/// Catalogo interno para desenvolvimento. Ele nao possui rota de producao e
/// usa somente dados ficticios para validar contratos visuais dos componentes.
class DesignSystemCatalogPage extends StatefulWidget {
  const DesignSystemCatalogPage({super.key});

  @override
  State<DesignSystemCatalogPage> createState() =>
      _DesignSystemCatalogPageState();
}

class _DesignSystemCatalogPageState extends State<DesignSystemCatalogPage> {
  final _searchController = TextEditingController();
  final _textController = TextEditingController();
  var _selectedChip = false;

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: FitTheme.dark(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Catalogo do Design System')),
        body: ListView(
          padding: const EdgeInsets.all(FitSpacing.s20),
          children: [
            const FitHeader(
              title: 'Componentes FitIA',
              subtitle: 'Dados de demonstracao para desenvolvimento.',
            ),
            _section(
              'Botoes',
              Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: [
                  FitButton(label: 'Principal', onPressed: _noop),
                  FitButton(
                    label: 'Secundario',
                    onPressed: _noop,
                    variant: FitButtonVariant.secondary,
                  ),
                  FitButton(
                    label: 'Perigo',
                    onPressed: _noop,
                    variant: FitButtonVariant.danger,
                  ),
                  FitIconButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'Mais opcoes',
                    onPressed: _noop,
                  ),
                ],
              ),
            ),
            _section(
              'Cards e metricas',
              Column(
                children: const [
                  FitHeroCard(
                    title: 'Treino demonstrativo',
                    subtitle: 'Componente desacoplado de dados reais.',
                    icon: FitIcons.workout,
                    eyebrow: 'Catalogo',
                  ),
                  SizedBox(height: FitSpacing.s12),
                  FitMetricRow(
                    children: [
                      FitMetric(
                        label: 'Passos',
                        value: '8.240',
                        icon: FitIcons.steps,
                      ),
                      FitMetric(
                        label: 'Treinos',
                        value: '4',
                        icon: FitIcons.workout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              'Chips e badges',
              Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: [
                  FitFilterChip(
                    label: 'Selecionavel',
                    selected: _selectedChip,
                    onSelected: (value) =>
                        setState(() => _selectedChip = value),
                  ),
                  const FitTagChip(label: 'Treino'),
                  const FitStatusChip(
                    label: 'Ativo',
                    tone: FitStatusTone.success,
                  ),
                  const FitBadge.ai(),
                  const FitBadge.offline(),
                ],
              ),
            ),
            _section(
              'Inputs e busca',
              Column(
                children: [
                  FitSearchField(controller: _searchController),
                  const SizedBox(height: FitSpacing.s12),
                  FitTextField(
                    controller: _textController,
                    label: 'Campo de demonstracao',
                    hintText: 'Digite algo',
                  ),
                ],
              ),
            ),
            _section(
              'Progresso e estados',
              Column(
                children: [
                  const FitProgressBar(
                    value: .64,
                    label: 'Meta semanal',
                    trailing: '64%',
                    animate: true,
                  ),
                  const SizedBox(height: FitSpacing.s16),
                  const FitCircularProgress(value: .64, showPercentage: true),
                  const SizedBox(height: FitSpacing.s16),
                  const FitOfflineState(compact: true),
                ],
              ),
            ),
            _section(
              'Overlays e feedback',
              Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: [
                  FitButton(
                    label: 'Confirmar',
                    onPressed: () => FitConfirmDialog.show(
                      context: context,
                      title: 'Confirmar acao',
                      message: 'Este e apenas um exemplo do catalogo.',
                    ),
                  ),
                  FitButton(
                    label: 'Acoes',
                    onPressed: () => FitActionSheet.show(
                      context: context,
                      title: 'Acoes de exemplo',
                      items: [
                        FitActionSheetItem(
                          label: 'Feedback de sucesso',
                          icon: Icons.check_rounded,
                          onTap: () {
                            Navigator.of(context).pop();
                            FitFeedback.showSuccess(context, 'Acao concluida.');
                          },
                        ),
                      ],
                    ),
                    variant: FitButtonVariant.outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FitSpacing.s24),
      child: FitSection(title: title, child: child),
    );
  }

  void _noop() {}
}
