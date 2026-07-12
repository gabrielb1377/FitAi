import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../services/metas_service.dart';
import '../../services/storage_service.dart';
import 'agenda_treinos_page.dart';
import 'calendario_treinos_page.dart';
import 'conquistas_page.dart';
import 'edit_profile_page.dart';
import 'evolucao_page.dart';
import 'metas_page.dart';
import 'notificacoes_page.dart';
import 'perfil_ia_page.dart';
import 'recordes_page.dart';
import 'widgets/profile/profile_goals.dart';
import 'widgets/profile/profile_header.dart';
import 'widgets/profile/profile_hub_data.dart';
import 'widgets/profile/profile_content_reveal.dart';
import 'widgets/profile/profile_local_data_notice.dart';
import 'widgets/profile/profile_records.dart';
import 'widgets/profile/profile_settings.dart';
import 'widgets/profile/profile_summary.dart';

class PerfilPage extends StatefulWidget {
  final String nome;
  final String peso;
  final String altura;
  final String idade;
  final int nivel;
  final bool conquistaPrimeiraCorrida;
  final bool conquista10Km;
  final Future<void> Function()? onPerfilAtualizado;

  const PerfilPage({
    super.key,
    required this.nome,
    required this.peso,
    required this.altura,
    required this.idade,
    required this.nivel,
    required this.conquistaPrimeiraCorrida,
    required this.conquista10Km,
    this.onPerfilAtualizado,
  });

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late Future<ProfileHubData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<ProfileHubData> _loadData() async {
    final xp = await StorageService.carregarXp();
    final history = await StorageService.carregarHistoricoTreinos();
    final records = await StorageService.carregarRecordes();
    final goals = await const MetasService().carregarMetas();
    return ProfileHubData.fromSources(
      xp: xp,
      history: history,
      records: records,
      goals: goals,
    );
  }

  Future<void> _reload() async {
    final next = _loadData();
    setState(() => _dataFuture = next);
    await next;
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    if (result == null) return;
    await StorageService.salvarPerfilUsuario(
      nome: result['nome'] ?? widget.nome,
      peso: result['peso'] ?? widget.peso,
      altura: result['altura'] ?? widget.altura,
      idade: result['idade'] ?? widget.idade,
    );
    await widget.onPerfilAtualizado?.call();
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil salvo com sucesso!')));
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileHubData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _state(const FitListSkeleton(itemCount: 4));
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return _state(
            FitErrorState(
              title: 'Perfil indisponivel',
              error: 'Nao foi possivel carregar seus dados locais.',
              onRetry: _reload,
            ),
          );
        }
        return _content(snapshot.data ?? const ProfileHubData.empty());
      },
    );
  }

  Widget _state(Widget content) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s20),
          child: Column(
            children: [
              ProfileHeader(
                name: widget.nome,
                level: widget.nivel,
                xp: 0,
                xpTarget: StorageService.xpNecessarioParaNivel(widget.nivel),
                onEdit: _editProfile,
              ),
              const SizedBox(height: FitSpacing.s20),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ProfileHubData data) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            key: const PageStorageKey('perfil-scroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              ProfileHeader(
                name: widget.nome,
                level: widget.nivel,
                xp: data.xp,
                xpTarget: StorageService.xpNecessarioParaNivel(widget.nivel),
                onEdit: _editProfile,
              ),
              const SizedBox(height: FitSpacing.s32),
              const ProfileLocalDataNotice(),
              const SizedBox(height: FitSpacing.s32),
              ProfileContentReveal(
                child: Column(
                  children: [
                    ProfileSummary(
                      weight: widget.peso,
                      height: widget.altura,
                      bmi: data.bmi(widget.peso, widget.altura),
                      activeDays: '${data.activeDays}',
                      completedWorkouts: '${data.completedWorkouts}',
                    ),
                    const SizedBox(height: FitSpacing.s32),
                    ProfileRecords(
                      records: data.records,
                      onViewAll: () => _open(const RecordesPage()),
                    ),
                    const SizedBox(height: FitSpacing.s32),
                    ProfileGoals(
                      goal: data.currentGoal,
                      onEdit: () => _open(const MetasPage()),
                    ),
                    const SizedBox(height: FitSpacing.s32),
                    ProfileSettings(
                      groups: [
                        ProfileSettingsGroup(
                          title: 'Conta',
                          items: [
                            ProfileSettingsItem(
                              label: 'Dados pessoais',
                              description: 'Nome, peso, altura e idade',
                              icon: Icons.person_outline_rounded,
                              onTap: _editProfile,
                            ),
                          ],
                        ),
                        ProfileSettingsGroup(
                          title: 'Aplicativo',
                          items: [
                            ProfileSettingsItem(
                              label: 'Notificacoes',
                              description: 'Lembretes e avisos do FitIA',
                              icon: Icons.notifications_outlined,
                              onTap: () => _open(const NotificacoesPage()),
                            ),
                          ],
                        ),
                        ProfileSettingsGroup(
                          title: 'Saude',
                          items: [
                            ProfileSettingsItem(
                              label: 'Perfil de saude',
                              description: 'Dados usados nas recomendacoes',
                              icon: Icons.health_and_safety_outlined,
                              onTap: () => _open(
                                PerfilIAPage(
                                  nome: widget.nome,
                                  idade: widget.idade,
                                  peso: widget.peso,
                                  altura: widget.altura,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ProfileSettingsGroup(
                          title: 'Acompanhamento',
                          items: [
                            ProfileSettingsItem(
                              label: 'Evolucao',
                              description: 'Historico e progresso',
                              icon: Icons.auto_graph_rounded,
                              onTap: () => _open(const EvolucaoPage()),
                            ),
                            ProfileSettingsItem(
                              label: 'Conquistas',
                              description: 'Marcos ja alcancados',
                              icon: Icons.emoji_events_outlined,
                              onTap: () => _open(const ConquistasPage()),
                            ),
                          ],
                        ),
                        ProfileSettingsGroup(
                          title: 'Planejamento',
                          items: [
                            ProfileSettingsItem(
                              label: 'Agenda de treinos',
                              description: 'Organize suas proximas sessoes',
                              icon: Icons.calendar_month_rounded,
                              onTap: () => _open(const AgendaTreinosPage()),
                            ),
                            ProfileSettingsItem(
                              label: 'Calendario de treinos',
                              description: 'Visualize sua rotina',
                              icon: Icons.event_available_rounded,
                              onTap: () => _open(const CalendarioTreinosPage()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
