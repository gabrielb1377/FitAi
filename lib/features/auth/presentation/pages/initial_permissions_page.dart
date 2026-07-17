import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/components/fit_loading.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_permissions_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';
import '../widgets/permission_tile.dart';

class InitialPermissionsPage extends StatefulWidget {
  const InitialPermissionsPage({super.key, this.permissionsService});

  final AuthPermissionsService? permissionsService;

  @override
  State<InitialPermissionsPage> createState() => _InitialPermissionsPageState();
}

class _InitialPermissionsPageState extends State<InitialPermissionsPage> {
  final _requesting = <AuthPermissionType>{};
  Map<AuthPermissionType, AuthPermissionStatus> _statuses = {
    for (final type in AuthPermissionType.values)
      type: AuthPermissionStatus.pending,
  };
  bool _isLoading = true;
  String? _message;

  AuthPermissionsService get _service =>
      widget.permissionsService ?? AuthPermissionsService();

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _service.loadStatuses();
      if (mounted) setState(() => _statuses = statuses);
    } on Object {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel carregar as permissoes.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _request(AuthPermissionType type) async {
    setState(() {
      _message = null;
      _requesting.add(type);
    });
    try {
      final status = await _service.request(type);
      if (mounted) {
        setState(() => _statuses = {..._statuses, type: status});
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel atualizar esta permissao.');
      }
    } finally {
      if (mounted) setState(() => _requesting.remove(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FitSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBackButton(),
            const SizedBox(height: FitSpacing.s24),
            const AuthPageTitle(
              title: 'Deixe o FitIA acompanhar voce.',
              subtitle:
                  'Escolha o que deseja conectar. Voce pode ajustar isso depois.',
            ),
            const SizedBox(height: FitSpacing.s24),
            if (_isLoading)
              const SizedBox(
                height: 84,
                child: FitLoading.inline(label: 'Carregando permissoes'),
              )
            else ...[
              PermissionTile(
                icon: Icons.directions_walk_rounded,
                title: 'Atividade fisica',
                description: 'Ajuda a acompanhar seus passos e movimentos.',
                status: _statusFor(AuthPermissionType.activity),
                isLoading: _requesting.contains(AuthPermissionType.activity),
                onRequest: () => _request(AuthPermissionType.activity),
              ),
              const SizedBox(height: FitSpacing.s12),
              PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Localizacao',
                description: 'Usada apenas quando voce iniciar uma corrida.',
                status: _statusFor(AuthPermissionType.location),
                isLoading: _requesting.contains(AuthPermissionType.location),
                onRequest: () => _request(AuthPermissionType.location),
              ),
              const SizedBox(height: FitSpacing.s12),
              PermissionTile(
                icon: Icons.health_and_safety_outlined,
                title: 'Health Connect',
                description: 'Importa dados de saude quando voce permitir.',
                status: _statusFor(AuthPermissionType.healthConnect),
                isLoading: _requesting.contains(
                  AuthPermissionType.healthConnect,
                ),
                onRequest: () => _request(AuthPermissionType.healthConnect),
              ),
              const SizedBox(height: FitSpacing.s12),
              PermissionTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notificacoes',
                description: 'Lembretes serao liberados em uma proxima versao.',
                status: _statusFor(AuthPermissionType.notifications),
                isLoading: false,
                onRequest: () => _request(AuthPermissionType.notifications),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: FitSpacing.s16),
              AuthInlineMessage(message: _message!),
            ],
            const SizedBox(height: FitSpacing.s32),
            FitButton(
              label: 'Continuar',
              expand: true,
              onPressed: () => AuthNavigation.replaceWithApp(context),
            ),
            const SizedBox(height: FitSpacing.s8),
            FitButton(
              label: 'Depois',
              variant: FitButtonVariant.ghost,
              expand: true,
              onPressed: () => AuthNavigation.replaceWithApp(context),
            ),
          ],
        ),
      ),
    );
  }

  AuthPermissionStatus _statusFor(AuthPermissionType type) =>
      _statuses[type] ?? AuthPermissionStatus.pending;
}
