import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/data/auth_service.dart';
import '../../application/settings_sync_summary.dart';
import 'personal_data_settings_page.dart';

/// Informacoes autenticadas e acoes criticas da conta, sem preferencias gerais.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final AuthService _authService = AuthService(bypassLogin: false);
  late final Future<_AccountData> _account = _load();

  Future<_AccountData> _load() async => _AccountData(
    session: await _authService.restoreSession(),
    sync: await SettingsSyncSummary.load(),
  );

  Future<void> _signOut(_AccountData data) async {
    final warning = data.sync.hasPending
        ? 'Existem ${data.sync.totalPending} pendencia(s) local(is). Sair nao apaga a fila, mas a proxima conta nao podera usa-la.'
        : 'Dados locais nao serao apagados ao sair.';
    final confirmed = await FitConfirmDialog.show(
      context: context,
      title: 'Sair da conta?',
      message: warning,
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await FitConfirmDialog.show(
      context: context,
      title: 'Excluir conta?',
      message:
          'Esta solicitacao ainda nao pode ser concluida porque o backend nao oferece exclusao segura. Nenhum dado sera removido.',
      confirmLabel: 'Entendi',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      const FitSnackBar(
        message: 'Conta nao foi excluida. A funcionalidade depende do backend.',
        tone: FitSnackBarTone.warning,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FutureBuilder<_AccountData>(
          future: _account,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Column(
                children: [
                  FitHeader(title: 'Conta'),
                  Expanded(child: FitLoading.fullScreen()),
                ],
              );
            }
            final data = snapshot.data!;
            final session = data.session;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s8,
                FitSpacing.s20,
                FitSpacing.s32,
              ),
              children: [
                FitHeader(
                  title: 'Conta',
                  subtitle: 'Identidade e seguranca da sessao',
                  showBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: FitSpacing.s8),
                FitCard(
                  variant: FitCardVariant.outlined,
                  child: Row(
                    children: [
                      FitAvatar(name: session?.name, size: FitAvatarSize.large),
                      const SizedBox(width: FitSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.name ?? 'Conta local',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: FitSpacing.s4),
                            Text(
                              session?.email ??
                                  'Nenhuma sessao autenticada disponivel',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                FitSection(
                  title: 'Conta',
                  child: FitCard(
                    variant: FitCardVariant.outlined,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        FitActionTile(
                          title: 'Dados pessoais',
                          description: 'Nome, peso, altura e idade opcionais',
                          icon: FitIcons.edit,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const PersonalDataSettingsPage(),
                            ),
                          ),
                        ),
                        const FitDivider(),
                        const FitListTile(
                          title: 'Sessao atual',
                          subtitle:
                              'Este dispositivo. Outras sessoes dependem de suporte do backend.',
                          leading: Icon(Icons.devices_outlined),
                          enabled: false,
                        ),
                      ],
                    ),
                  ),
                ),
                FitSection(
                  title: 'Acoes da conta',
                  child: FitCard(
                    variant: FitCardVariant.outlined,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        FitActionTile(
                          title: 'Sair',
                          description: data.sync.hasPending
                              ? 'Ha sincronizacao local pendente.'
                              : 'Mantem seus dados locais.',
                          icon: Icons.logout_rounded,
                          onTap: () => _signOut(data),
                        ),
                        const FitDivider(),
                        FitActionTile(
                          title: 'Excluir conta',
                          description:
                              'Fluxo visual; nenhum dado sera excluido sem backend.',
                          icon: FitIcons.delete,
                          destructive: true,
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountData {
  const _AccountData({required this.session, required this.sync});

  final AuthSession? session;
  final SettingsSyncSummary sync;
}
