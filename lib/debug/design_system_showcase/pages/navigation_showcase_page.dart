import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra estruturas de navegação sem registrar rotas no app principal.
class NavigationShowcasePage extends StatefulWidget {
  const NavigationShowcasePage({super.key});

  @override
  State<NavigationShowcasePage> createState() => _NavigationShowcasePageState();
}

class _NavigationShowcasePageState extends State<NavigationShowcasePage> {
  final _search = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Navigation',
        subtitle: 'FitTopBar',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        actions: const [
          FitIconButton(
            icon: FitIcons.more,
            tooltip: 'Mais opções',
            onPressed: _noop,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Cabeçalhos',
              child: Column(
                children: [
                  const FitSectionHeader(
                    title: 'FitSectionHeader',
                    subtitle: 'Com ação contextual',
                    onViewAll: _noop,
                  ),
                  const SizedBox(height: FitSpacing.s16),
                  FitSearchBar(controller: _search, hintText: 'FitSearchBar'),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Containers',
              child: Column(
                children: [
                  FitPrimaryButton(
                    label: 'Abrir bottom sheet',
                    fullWidth: true,
                    onPressed: () => FitBottomSheetContainer.show<void>(
                      context: context,
                      title: 'FitBottomSheetContainer',
                      child: const Text('Conteúdo contextual.'),
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  FitOutlinedButton(
                    label: 'Abrir dialog',
                    fullWidth: true,
                    onPressed: () => FitDialogContainer.show<void>(
                      context: context,
                      title: 'FitDialogContainer',
                      message: 'Confirmações curtas usam esta superfície.',
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  SizedBox(
                    height: FitLayout.navigationBarHeight + FitSpacing.s32,
                    child: const FitFABContainer(
                      child: FitFAB(
                        icon: FitIcons.add,
                        tooltip: 'Adicionar',
                        onPressed: _noop,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Bottom navigation',
              child: FitBottomNavigation(
                selectedIndex: _selectedIndex,
                destinations: const [
                  FitNavigationDestination(label: 'Home', icon: FitIcons.home),
                  FitNavigationDestination(
                    label: 'Planos',
                    icon: FitIcons.plans,
                  ),
                  FitNavigationDestination(
                    label: 'Perfil',
                    icon: FitIcons.profile,
                  ),
                ],
                onSelected: (value) => setState(() => _selectedIndex = value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}
