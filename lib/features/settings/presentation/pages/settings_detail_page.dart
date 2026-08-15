import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/environment_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/settings.dart';
import '../../application/settings_sync_summary.dart';
import 'personal_data_settings_page.dart';

enum SettingsDestination {
  personal,
  appearance,
  locale,
  units,
  workout,
  rest,
  notifications,
  privacy,
  security,
  data,
  sync,
  integrations,
  premium,
  help,
  about,
  developer,
}

class SettingsDetailPage extends StatefulWidget {
  const SettingsDetailPage({
    super.key,
    required this.destination,
    this.controller,
  });

  final SettingsDestination destination;
  final SettingsController? controller;

  @override
  State<SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<SettingsDetailPage> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsRuntime.controller;
    if (_controller.state.status == SettingsLoadStatus.initial) {
      _controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destination == SettingsDestination.personal) {
      return const PersonalDataSettingsPage();
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            if (!state.isReady) return _LoadingOrError(state: state);
            return _SettingsBody(
              destination: widget.destination,
              settings: state.snapshot!.settings,
              onUpdate: _controller.update,
            );
          },
        ),
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.state});

  final SettingsViewState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FitHeader(
          title: 'Configuracoes',
          showBackButton: true,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: state.status == SettingsLoadStatus.error
              ? FitErrorState(
                  error: 'Nao foi possivel carregar suas preferencias locais.',
                  onRetry: SettingsRuntime.controller.load,
                )
              : const FitLoading.fullScreen(label: 'Carregando configuracoes'),
        ),
      ],
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.destination,
    required this.settings,
    required this.onUpdate,
  });

  final SettingsDestination destination;
  final AppSettings settings;
  final Future<void> Function(AppSettings Function(AppSettings)) onUpdate;

  @override
  Widget build(BuildContext context) {
    final content = switch (destination) {
      SettingsDestination.appearance => _appearance(context),
      SettingsDestination.locale => _locale(context),
      SettingsDestination.units => _units(context),
      SettingsDestination.workout => _workout(context),
      SettingsDestination.rest => _rest(context),
      SettingsDestination.notifications => _notifications(context),
      SettingsDestination.privacy => _privacy(context),
      SettingsDestination.security => _security(context),
      SettingsDestination.data => _data(context),
      SettingsDestination.sync => _sync(context),
      SettingsDestination.integrations => _integrations(context),
      SettingsDestination.premium => _premium(context),
      SettingsDestination.help => _help(context),
      SettingsDestination.about => _about(context),
      SettingsDestination.developer => _developer(context),
      SettingsDestination.personal => const SizedBox.shrink(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        FitSpacing.s32,
      ),
      children: [
        FitHeader(
          title: _title(destination),
          subtitle: _subtitle(destination),
          showBackButton: true,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: FitSpacing.s8),
        content,
      ],
    );
  }

  Widget _appearance(BuildContext context) => _SettingsCard(
    children: [
      _ChoiceTile<AppThemePreference>(
        title: 'Usar tema do sistema',
        description: 'Acompanha a aparencia configurada no dispositivo.',
        value: AppThemePreference.system,
        groupValue: settings.device.appearance.theme,
        onChanged: _setTheme,
      ),
      const FitDivider(),
      _ChoiceTile<AppThemePreference>(
        title: 'Escuro',
        description: 'Superficies profundas para ambientes com pouca luz.',
        value: AppThemePreference.dark,
        groupValue: settings.device.appearance.theme,
        onChanged: _setTheme,
      ),
      const FitDivider(),
      _ChoiceTile<AppThemePreference>(
        title: 'Claro',
        description: 'Contraste limpo para ambientes iluminados.',
        value: AppThemePreference.light,
        groupValue: settings.device.appearance.theme,
        onChanged: _setTheme,
      ),
      const FitDivider(),
      FitSwitch(
        label: 'Reduzir animacoes',
        description:
            'Preferencia salva para telas que ja suportam movimento reduzido.',
        value: settings.device.appearance.reduceMotion,
        onChanged: (value) => onUpdate(
          (current) => current.copyWith(
            device: current.device.copyWith(
              appearance: current.device.appearance.copyWith(
                reduceMotion: value,
                metadata: current.device.appearance.metadata.touch(),
              ),
            ),
          ),
        ),
      ),
      const FitDivider(),
      const FitListTile(
        title: 'Contraste aumentado',
        subtitle:
            'Sera disponibilizado quando o tema oficial tiver esta variante.',
        leading: Icon(Icons.contrast_rounded),
        enabled: false,
      ),
    ],
  );

  Widget _locale(BuildContext context) => _SettingsCard(
    children: [
      _ChoiceTile<AppLocalePreference>(
        title: 'Idioma do sistema',
        description: 'Usa o idioma configurado no aparelho.',
        value: AppLocalePreference.system,
        groupValue: settings.device.locale.locale,
        onChanged: (value) => _setLocale(value),
      ),
      const FitDivider(),
      _ChoiceTile<AppLocalePreference>(
        title: 'Portugues (Brasil)',
        description: 'Idioma atualmente suportado pelo FitIA.',
        value: AppLocalePreference.portugueseBrazil,
        groupValue: settings.device.locale.locale,
        onChanged: (value) => _setLocale(value),
      ),
    ],
  );

  Widget _units(BuildContext context) => _SettingsCard(
    children: [
      _selector(
        context,
        title: 'Peso',
        value: settings.account.units.weight == WeightUnit.kilogram
            ? 'kg'
            : 'lb',
        options: const {
          'Quilogramas (kg)': WeightUnit.kilogram,
          'Libras (lb)': WeightUnit.pound,
        },
        selected: settings.account.units.weight,
        onSelected: (value) => _setUnits(weight: value),
      ),
      const FitDivider(),
      _selector(
        context,
        title: 'Altura',
        value: settings.account.units.height == HeightUnit.centimeter
            ? 'cm'
            : 'pes e polegadas',
        options: const {
          'Centimetros (cm)': HeightUnit.centimeter,
          'Pes e polegadas': HeightUnit.feetInches,
        },
        selected: settings.account.units.height,
        onSelected: (value) => _setUnits(height: value),
      ),
      const FitDivider(),
      _selector(
        context,
        title: 'Distancia',
        value: settings.account.units.distance == DistanceUnit.kilometer
            ? 'km'
            : 'mi',
        options: const {
          'Quilometros (km)': DistanceUnit.kilometer,
          'Milhas (mi)': DistanceUnit.mile,
        },
        selected: settings.account.units.distance,
        onSelected: (value) => _setUnits(distance: value),
      ),
      const FitDivider(),
      _selector(
        context,
        title: 'Ritmo',
        value: settings.account.units.pace == PaceUnit.minutesPerKilometer
            ? 'min/km'
            : 'min/mi',
        options: const {
          'Minutos por km': PaceUnit.minutesPerKilometer,
          'Minutos por milha': PaceUnit.minutesPerMile,
        },
        selected: settings.account.units.pace,
        onSelected: (value) => _setUnits(pace: value),
      ),
    ],
  );

  Widget _workout(BuildContext context) => _SettingsCard(
    children: [
      FitSwitch(
        label: 'Mostrar carga sugerida',
        description:
            'Mantem a sugestao de progressao disponivel durante o treino.',
        value: settings.account.workout.showSuggestedLoad,
        onChanged: (value) => onUpdate(
          (current) => current.copyWith(
            account: current.account.copyWith(
              workout: current.account.workout.copyWith(
                showSuggestedLoad: value,
                metadata: current.account.workout.metadata.touch(),
              ),
            ),
          ),
        ),
      ),
      const FitDivider(),
      const FitListTile(
        title: 'Confirmacao e transicao automatica',
        subtitle:
            'A execucao atual mantem confirmacao explicita e avancar manual.',
        leading: Icon(FitIcons.info),
        enabled: false,
      ),
    ],
  );

  Widget _rest(BuildContext context) => _SettingsCard(
    children: [
      _selector(
        context,
        title: 'Descanso padrao',
        value: '${settings.account.rest.defaultRestSeconds} s',
        options: const {
          '45 segundos': 45,
          '60 segundos': 60,
          '90 segundos': 90,
          '120 segundos': 120,
        },
        selected: settings.account.rest.defaultRestSeconds,
        onSelected: (value) => _setRest(defaultRestSeconds: value),
      ),
      const FitDivider(),
      _selector(
        context,
        title: 'Atalho de tempo',
        value: '+${settings.account.rest.quickAddSeconds} s',
        options: const {'+15 segundos': 15, '+30 segundos': 30},
        selected: settings.account.rest.quickAddSeconds,
        onSelected: (value) => _setRest(quickAddSeconds: value),
      ),
      const FitDivider(),
      const FitListTile(
        title: 'Som, vibracao e alertas',
        subtitle:
            'Ainda indisponiveis: o FitIA nao solicita permissao nem reproduz feedback falso.',
        leading: Icon(Icons.volume_up_outlined),
        enabled: false,
      ),
    ],
  );

  Widget _notifications(BuildContext context) => _SettingsCard(
    children: [
      _notificationSwitch(
        'Lembretes de treino',
        settings.account.notifications.workoutReminders,
        (value) => _setNotifications(workoutReminders: value),
      ),
      const FitDivider(),
      _notificationSwitch(
        'Progresso',
        settings.account.notifications.progressUpdates,
        (value) => _setNotifications(progressUpdates: value),
      ),
      const FitDivider(),
      _notificationSwitch(
        'Metas',
        settings.account.notifications.goalUpdates,
        (value) => _setNotifications(goalUpdates: value),
      ),
      const FitDivider(),
      _notificationSwitch(
        'Sistema',
        settings.account.notifications.systemUpdates,
        (value) => _setNotifications(systemUpdates: value),
      ),
      const Padding(
        padding: EdgeInsets.all(FitSpacing.s12),
        child: Text(
          'As preferencias sao salvas localmente. Push ainda nao esta configurado.',
        ),
      ),
    ],
  );

  Widget _privacy(BuildContext context) => _SettingsCard(
    children: [
      _privacySwitch(
        'Perfil visivel',
        'Mantem seu perfil privado enquanto nao existe recurso social.',
        settings.account.privacy.profileVisible,
        (value) => _setPrivacy(profileVisible: value),
      ),
      const FitDivider(),
      _privacySwitch(
        'Compartilhar atividades',
        'Nenhuma atividade e publicada neste sprint.',
        settings.account.privacy.shareActivities,
        (value) => _setPrivacy(shareActivities: value),
      ),
      const FitDivider(),
      _privacySwitch(
        'Mapas de rota',
        'Mapas permanecem privados por padrao.',
        settings.account.privacy.shareRouteMaps,
        (value) => _setPrivacy(shareRouteMaps: value),
      ),
      const FitDivider(),
      _privacySwitch(
        'Dados de saude',
        'Consentimento salvo; nenhuma integracao de saude e conectada neste sprint.',
        settings.account.privacy.healthDataConsent,
        (value) => _setPrivacy(healthDataConsent: value),
      ),
      const FitDivider(),
      _privacySwitch(
        'Personalizacao por IA',
        'Consentimento salvo; Coach conversacional nao esta ativo.',
        settings.account.privacy.aiPersonalizationConsent,
        (value) => _setPrivacy(aiPersonalizationConsent: value),
      ),
      const FitDivider(),
      _privacySwitch(
        'Analytics',
        'Nao habilita coleta nova sem uma integracao explicita.',
        settings.account.privacy.analyticsConsent,
        (value) => _setPrivacy(analyticsConsent: value),
      ),
    ],
  );

  Widget _security(BuildContext context) => _SettingsCard(
    children: const [
      FitListTile(
        title: 'Senha',
        subtitle: 'Gerenciada pelo fluxo de autenticacao atual.',
        leading: Icon(FitIcons.lock),
        enabled: false,
      ),
      FitDivider(),
      FitListTile(
        title: 'Biometria e autenticacao em duas etapas',
        subtitle:
            'Indisponiveis ate existir suporte seguro no aplicativo e backend.',
        leading: Icon(Icons.fingerprint_rounded),
        enabled: false,
      ),
      FitDivider(),
      FitListTile(
        title: 'Sessoes em outros dispositivos',
        subtitle: 'O backend atual nao fornece uma lista de sessoes.',
        leading: Icon(Icons.devices_outlined),
        enabled: false,
      ),
    ],
  );

  Widget _data(BuildContext context) => _SettingsCard(
    children: [
      FitActionTile(
        title: 'Solicitar copia dos dados',
        description: 'Perfil, planos, historico, atividades e progressao.',
        icon: FitIcons.share,
        onTap: () => _showUnavailable(
          context,
          'Exportacao ainda nao esta conectada a uma infraestrutura segura. Nenhum arquivo foi criado.',
        ),
      ),
      const FitDivider(),
      const Padding(
        padding: EdgeInsets.all(FitSpacing.s12),
        child: Text(
          'Quando disponivel, a exportacao mostrara formato, periodo e status antes de criar qualquer arquivo.',
        ),
      ),
    ],
  );

  Widget _sync(BuildContext context) => FutureBuilder<SettingsSyncSummary>(
    future: SettingsSyncSummary.load(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const FitLoadingCard(
          semanticLabel: 'Lendo estado local de sincronizacao',
        );
      }
      if (snapshot.hasError) {
        return FitErrorState(
          error: 'Nao foi possivel ler as pendencias locais.',
          onRetry: () => Navigator.of(context).maybePop(),
        );
      }
      final summary = snapshot.data!;
      return _SettingsCard(
        children: [
          FitListTile(
            title: summary.hasPending
                ? '${summary.totalPending} pendencia(s) local(is)'
                : 'Nenhuma pendencia identificada',
            subtitle:
                'Fila geral: ${summary.pendingOutbox} | Corridas: ${summary.pendingRuns} | Passos: ${summary.pendingSteps} | Progressao: ${summary.pendingProgression}',
            leading: Icon(
              summary.hasPending ? FitIcons.offline : FitIcons.success,
            ),
          ),
          const FitDivider(),
          FitActionTile(
            title: 'Tentar sincronizar agora',
            description:
                'Envia apenas a fila ja existente quando houver conexao.',
            icon: FitIcons.retry,
            onTap: () async {
              await SettingsSyncSummary.retry();
              if (context.mounted) {
                _showMessage(context, 'Tentativa de sincronizacao iniciada.');
              }
            },
          ),
          const FitDivider(),
          const Padding(
            padding: EdgeInsets.all(FitSpacing.s12),
            child: Text(
              'O status confirma somente dados que a infraestrutura atual consegue observar. Itens locais nao sao mostrados como sincronizados.',
            ),
          ),
        ],
      );
    },
  );

  Widget _integrations(BuildContext context) => _SettingsCard(
    children: const [
      FitListTile(
        title: 'Google Health Connect',
        subtitle: 'Nao configurado. Nenhuma permissao sera solicitada agora.',
        leading: Icon(Icons.health_and_safety_outlined),
        enabled: false,
      ),
      FitDivider(),
      FitListTile(
        title: 'Apple Health',
        subtitle: 'Planejado para uma etapa futura.',
        leading: Icon(Icons.favorite_outline_rounded),
        enabled: false,
      ),
      FitDivider(),
      FitListTile(
        title: 'Garmin e Strava',
        subtitle: 'Planejados. Nenhuma conta sera conectada neste sprint.',
        leading: Icon(FitIcons.integration),
        enabled: false,
      ),
    ],
  );

  Widget _premium(BuildContext context) => _SettingsCard(
    children: [
      const FitListTile(
        title: 'Assinatura',
        subtitle:
            'O contrato comercial ainda nao esta configurado para esta conta.',
        leading: Icon(FitIcons.premium),
        enabled: false,
      ),
      const FitDivider(),
      FitActionTile(
        title: 'Gerenciar assinatura',
        description:
            'Placeholder: nenhum checkout, preco ou compra sera aberta.',
        icon: FitIcons.payment,
        onTap: () => _showUnavailable(
          context,
          'O gerenciamento de assinatura ainda nao esta disponivel.',
        ),
      ),
    ],
  );

  Widget _help(BuildContext context) => _SettingsCard(
    children: [
      FitActionTile(
        title: 'Como iniciar um treino',
        description: 'Abra Planos, selecione um treino e use o botao iniciar.',
        icon: FitIcons.workout,
        onTap: () => _showMessage(
          context,
          'Tutorial detalhado sera disponibilizado na central de ajuda.',
        ),
      ),
      const FitDivider(),
      FitActionTile(
        title: 'Relatar um problema',
        description: 'Canal de suporte ainda nao esta conectado.',
        icon: FitIcons.error,
        onTap: () => _showUnavailable(
          context,
          'Nao ha canal configurado para envio de relatorios neste build.',
        ),
      ),
      const FitDivider(),
      FitActionTile(
        title: 'Enviar feedback',
        description: 'Nenhum dado sera enviado sem um canal seguro.',
        icon: FitIcons.notes,
        onTap: () => _showUnavailable(
          context,
          'O feedback ainda nao possui destino configurado.',
        ),
      ),
    ],
  );

  Widget _about(BuildContext context) => _SettingsCard(
    children: [
      const FitListTile(
        title: 'FitIA',
        subtitle: 'Versao 1.0.0 (build 1)',
        leading: Icon(FitIcons.info),
      ),
      const FitDivider(),
      FitListTile(
        title: 'Ambiente',
        subtitle: EnvironmentConfig.appEnvironment,
        leading: const Icon(Icons.code_rounded),
      ),
      const FitDivider(),
      const FitListTile(
        title: 'Termos, privacidade e licencas',
        subtitle:
            'Documentos serao vinculados quando os enderecos oficiais existirem.',
        leading: Icon(FitIcons.list),
        enabled: false,
      ),
    ],
  );

  Widget _developer(BuildContext context) {
    if (!kDebugMode) {
      return const FitEmptyState(
        icon: FitIcons.lock,
        title: 'Indisponivel',
        description: 'Developer Mode existe somente em builds de debug.',
      );
    }
    final baseUrl =
        EnvironmentConfig.apiBaseUrl ?? 'Nao configurada (modo offline)';
    return _SettingsCard(
      children: [
        FitListTile(
          title: 'Ambiente',
          subtitle: EnvironmentConfig.appEnvironment,
          leading: const Icon(Icons.developer_mode_outlined),
        ),
        const FitDivider(),
        FitListTile(
          title: 'Base URL',
          subtitle: baseUrl,
          leading: const Icon(Icons.dns_outlined),
        ),
        const FitDivider(),
        FitActionTile(
          title: 'Offline Workout Vertical Slice',
          description: 'Abre o ambiente isolado de teste offline.',
          icon: FitIcons.storage,
          onTap: () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.debugWorkoutVerticalSlice),
        ),
        const FitDivider(),
        const FitListTile(
          title: 'Dados seed',
          subtitle:
              'Fixtures de debug sao mantidas somente em memoria; nao ha dados seed persistidos para limpar.',
          leading: Icon(FitIcons.info),
          enabled: false,
        ),
      ],
    );
  }

  Widget _notificationSwitch(
    String label,
    bool value,
    ValueChanged<bool> changed,
  ) => FitSwitch(
    label: label,
    description: 'Preferencia local; entrega push nao esta configurada.',
    value: value,
    onChanged: changed,
  );

  Widget _privacySwitch(
    String label,
    String description,
    bool value,
    ValueChanged<bool> changed,
  ) => FitSwitch(
    label: label,
    description: description,
    value: value,
    onChanged: changed,
  );

  Widget _selector<T>(
    BuildContext context, {
    required String title,
    required String value,
    required Map<String, T> options,
    required T selected,
    required ValueChanged<T> onSelected,
  }) => FitActionTile(
    title: title,
    description: value,
    icon: FitIcons.settings,
    onTap: () async {
      final selectedValue = await FitBottomSheet.show<T>(
        context: context,
        title: title,
        child: Column(
          children: [
            for (final option in options.entries)
              _ChoiceTile<T>(
                title: option.key,
                value: option.value,
                groupValue: selected,
                onChanged: (next) => Navigator.of(context).pop(next),
              ),
          ],
        ),
      );
      if (selectedValue != null) onSelected(selectedValue);
    },
  );

  void _setLocale(AppLocalePreference value) => onUpdate(
    (current) => current.copyWith(
      device: current.device.copyWith(
        locale: current.device.locale.copyWith(
          locale: value,
          metadata: current.device.locale.metadata.touch(),
        ),
      ),
    ),
  );

  void _setTheme(AppThemePreference value) => onUpdate(
    (current) => current.copyWith(
      device: current.device.copyWith(
        appearance: current.device.appearance.copyWith(
          theme: value,
          metadata: current.device.appearance.metadata.touch(),
        ),
      ),
    ),
  );

  void _setUnits({
    WeightUnit? weight,
    HeightUnit? height,
    DistanceUnit? distance,
    PaceUnit? pace,
  }) => onUpdate(
    (current) => current.copyWith(
      account: current.account.copyWith(
        units: current.account.units.copyWith(
          weight: weight,
          height: height,
          distance: distance,
          pace: pace,
          metadata: current.account.units.metadata.touch(),
        ),
      ),
    ),
  );

  void _setRest({int? defaultRestSeconds, int? quickAddSeconds}) => onUpdate(
    (current) => current.copyWith(
      account: current.account.copyWith(
        rest: current.account.rest.copyWith(
          defaultRestSeconds: defaultRestSeconds,
          quickAddSeconds: quickAddSeconds,
          metadata: current.account.rest.metadata.touch(),
        ),
      ),
    ),
  );

  void _setNotifications({
    bool? workoutReminders,
    bool? progressUpdates,
    bool? goalUpdates,
    bool? systemUpdates,
  }) => onUpdate(
    (current) => current.copyWith(
      account: current.account.copyWith(
        notifications: current.account.notifications.copyWith(
          workoutReminders: workoutReminders,
          progressUpdates: progressUpdates,
          goalUpdates: goalUpdates,
          systemUpdates: systemUpdates,
          metadata: current.account.notifications.metadata.touch(),
        ),
      ),
    ),
  );

  void _setPrivacy({
    bool? profileVisible,
    bool? shareActivities,
    bool? shareRouteMaps,
    bool? healthDataConsent,
    bool? aiPersonalizationConsent,
    bool? analyticsConsent,
  }) => onUpdate(
    (current) => current.copyWith(
      account: current.account.copyWith(
        privacy: current.account.privacy.copyWith(
          profileVisible: profileVisible,
          shareActivities: shareActivities,
          shareRouteMaps: shareRouteMaps,
          healthDataConsent: healthDataConsent,
          aiPersonalizationConsent: aiPersonalizationConsent,
          analyticsConsent: analyticsConsent,
          metadata: current.account.privacy.metadata.touch(),
        ),
      ),
    ),
  );

  void _showUnavailable(BuildContext context, String message) =>
      FitDialog.show<void>(
        context: context,
        title: 'Ainda indisponivel',
        message: message,
        actions: [
          FitGhostButton(
            label: 'Entendi',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );

  void _showMessage(BuildContext context, String message) =>
      FitSnackBar(message: message).show(context);

  String _title(SettingsDestination value) => switch (value) {
    SettingsDestination.personal => 'Dados pessoais',
    SettingsDestination.appearance => 'Aparencia',
    SettingsDestination.locale => 'Idioma',
    SettingsDestination.units => 'Unidades',
    SettingsDestination.workout => 'Preferencias de treino',
    SettingsDestination.rest => 'Descanso e feedback',
    SettingsDestination.notifications => 'Notificacoes',
    SettingsDestination.privacy => 'Privacidade',
    SettingsDestination.security => 'Seguranca',
    SettingsDestination.data => 'Dados e exportacao',
    SettingsDestination.sync => 'Sincronizacao',
    SettingsDestination.integrations => 'Integracoes',
    SettingsDestination.premium => 'Assinatura',
    SettingsDestination.help => 'Ajuda',
    SettingsDestination.about => 'Sobre o FitIA',
    SettingsDestination.developer => 'Developer Mode',
  };

  String _subtitle(SettingsDestination value) => switch (value) {
    SettingsDestination.privacy => 'Controle com linguagem clara.',
    SettingsDestination.sync => 'Leitura honesta do estado local.',
    SettingsDestination.developer => 'Somente para debug.',
    _ => 'Preferencias salvas no dispositivo quando aplicavel.',
  };
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => FitCard(
    variant: FitCardVariant.outlined,
    padding: EdgeInsets.zero,
    child: Column(children: children),
  );
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.description,
  });
  final String title;
  final String? description;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: groupValue,
    onChanged: (next) {
      if (next != null) {
        onChanged(next);
      }
    },
    child: ListTile(
      minTileHeight: FitLayout.listTileMinHeight,
      leading: Radio<T>(value: value),
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      onTap: () => onChanged(value),
    ),
  );
}
