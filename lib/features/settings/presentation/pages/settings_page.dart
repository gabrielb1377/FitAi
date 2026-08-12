import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../application/settings_runtime.dart';
import '../widgets/settings_group.dart';
import 'account_settings_page.dart';
import 'settings_detail_page.dart';

/// Hub organizado de preferencias. A Conta permanece em uma pagina separada.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.initialDestination, this.controller});

  final SettingsDestination? initialDestination;
  final SettingsController? controller;

  @override
  Widget build(BuildContext context) {
    if (initialDestination != null) {
      return SettingsDetailPage(
        destination: initialDestination!,
        controller: controller,
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey('settings-scroll'),
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s20,
            FitSpacing.s8,
            FitSpacing.s20,
            FitSpacing.s32,
          ),
          children: [
            FitHeader(
              title: 'Configuracoes',
              subtitle: 'Preferencias, dados e suporte',
              showBackButton: Navigator.of(context).canPop(),
              onBack: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
            ),
            SettingsGroup(
              title: 'Conta',
              items: [
                SettingsGroupItem(
                  title: 'Conta',
                  description: 'Sessao, dados pessoais e acoes da conta',
                  icon: FitIcons.profile,
                  onTap: () => _open(context, const AccountSettingsPage()),
                ),
                SettingsGroupItem(
                  title: 'Dados pessoais',
                  description: 'Nome, objetivo, peso e altura',
                  icon: FitIcons.edit,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.personal),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Aplicativo',
              items: [
                SettingsGroupItem(
                  title: 'Aparencia',
                  description: 'Tema e preferencias de movimento',
                  icon: Icons.palette_outlined,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.appearance),
                ),
                SettingsGroupItem(
                  title: 'Idioma',
                  description: 'Idioma do sistema ou portugues',
                  icon: Icons.language_rounded,
                  onTap: () => _openDetail(context, SettingsDestination.locale),
                ),
                SettingsGroupItem(
                  title: 'Unidades',
                  description: 'Peso, distancia, ritmo e horario',
                  icon: FitIcons.distance,
                  onTap: () => _openDetail(context, SettingsDestination.units),
                ),
                SettingsGroupItem(
                  title: 'Notificacoes',
                  description: 'Preferencias locais de avisos',
                  icon: FitIcons.notification,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.notifications),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Treino',
              items: [
                SettingsGroupItem(
                  title: 'Preferencias de treino',
                  description: 'Carga sugerida e comportamento da sessao',
                  icon: FitIcons.workout,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.workout),
                ),
                SettingsGroupItem(
                  title: 'Descanso e feedback',
                  description: 'Tempo padrao e atalhos do cronometro',
                  icon: FitIcons.timer,
                  onTap: () => _openDetail(context, SettingsDestination.rest),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Dados e privacidade',
              items: [
                SettingsGroupItem(
                  title: 'Privacidade',
                  description: 'Consentimentos e visibilidade',
                  icon: FitIcons.private,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.privacy),
                ),
                SettingsGroupItem(
                  title: 'Seguranca',
                  description: 'Senha e sessoes autenticadas',
                  icon: FitIcons.lock,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.security),
                ),
                SettingsGroupItem(
                  title: 'Dados e exportacao',
                  description: 'Solicitacao de copia dos seus dados',
                  icon: FitIcons.share,
                  onTap: () => _openDetail(context, SettingsDestination.data),
                ),
                SettingsGroupItem(
                  title: 'Sincronizacao',
                  description: 'Pendencias e estado offline',
                  icon: FitIcons.backup,
                  onTap: () => _openDetail(context, SettingsDestination.sync),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Conexoes e suporte',
              items: [
                SettingsGroupItem(
                  title: 'Integracoes',
                  description: 'Health Connect e servicos planejados',
                  icon: FitIcons.integration,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.integrations),
                ),
                SettingsGroupItem(
                  title: 'Assinatura',
                  description: 'Status e beneficios quando disponiveis',
                  icon: FitIcons.premium,
                  onTap: () =>
                      _openDetail(context, SettingsDestination.premium),
                ),
                SettingsGroupItem(
                  title: 'Ajuda',
                  description: 'Orientacoes e contato',
                  icon: FitIcons.info,
                  onTap: () => _openDetail(context, SettingsDestination.help),
                ),
                SettingsGroupItem(
                  title: 'Sobre o FitIA',
                  description: 'Versao, ambiente e licencas',
                  icon: FitIcons.info,
                  onTap: () => _openDetail(context, SettingsDestination.about),
                ),
                if (_isDebug)
                  SettingsGroupItem(
                    title: 'Developer Mode',
                    description: 'Ferramentas locais de desenvolvimento',
                    icon: Icons.developer_mode_outlined,
                    onTap: () =>
                        _openDetail(context, SettingsDestination.developer),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _isDebug => kDebugMode;

  void _openDetail(BuildContext context, SettingsDestination destination) {
    _open(
      context,
      SettingsDetailPage(destination: destination, controller: controller),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));
  }
}
