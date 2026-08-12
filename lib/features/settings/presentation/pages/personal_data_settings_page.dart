import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../services/storage_service.dart';

/// Edicao dos poucos dados pessoais efetivamente consumidos pelo produto.
class PersonalDataSettingsPage extends StatefulWidget {
  const PersonalDataSettingsPage({super.key});

  @override
  State<PersonalDataSettingsPage> createState() =>
      _PersonalDataSettingsPageState();
}

class _PersonalDataSettingsPageState extends State<PersonalDataSettingsPage> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await StorageService.carregarPerfilUsuarioLocal();
    _name.text = values['nome'] ?? '';
    _weight.text = values['peso'] ?? '';
    _height.text = values['altura'] ?? '';
    _age.text = values['idade'] ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      const FitSnackBar(
        message: 'Informe como deseja ser chamado.',
        tone: FitSnackBarTone.warning,
      ).show(context);
      return;
    }
    setState(() => _saving = true);
    await StorageService.salvarPerfilUsuario(
      nome: _name.text.trim(),
      peso: _weight.text.trim(),
      altura: _height.text.trim(),
      idade: _age.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    const FitSnackBar(
      message: 'Dados pessoais salvos neste dispositivo.',
      tone: FitSnackBarTone.success,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Column(
                children: [
                  FitHeader(title: 'Dados pessoais'),
                  Expanded(child: FitLoading.fullScreen()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  FitSpacing.s20,
                  FitSpacing.s8,
                  FitSpacing.s20,
                  FitSpacing.s32,
                ),
                children: [
                  FitHeader(
                    title: 'Dados pessoais',
                    subtitle: 'Usados para personalizar a experiencia.',
                    showBackButton: true,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  FitCard(
                    variant: FitCardVariant.outlined,
                    child: Column(
                      children: [
                        FitTextField(
                          controller: _name,
                          label: 'Nome',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: FitSpacing.s16),
                        FitNumberField(
                          controller: _weight,
                          label: 'Peso',
                          helperText:
                              'Opcional. Usado apenas em metricas pessoais.',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: FitSpacing.s16),
                        FitNumberField(
                          controller: _height,
                          label: 'Altura',
                          helperText:
                              'Opcional. Usada apenas em metricas pessoais.',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: FitSpacing.s16),
                        FitNumberField(
                          controller: _age,
                          label: 'Idade',
                          helperText:
                              'Opcional. Nao gera diagnosticos de saude.',
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s20),
                  FitPrimaryButton(
                    label: 'Salvar dados',
                    fullWidth: true,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
