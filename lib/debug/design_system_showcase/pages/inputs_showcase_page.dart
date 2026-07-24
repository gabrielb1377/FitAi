import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra todos os controles públicos do módulo Inputs.
class InputsShowcasePage extends StatefulWidget {
  const InputsShowcasePage({super.key});

  @override
  State<InputsShowcasePage> createState() => _InputsShowcasePageState();
}

class _InputsShowcasePageState extends State<InputsShowcasePage> {
  final _text = TextEditingController();
  final _search = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _number = TextEditingController();
  final _otp = TextEditingController();

  String? _level = 'Intermediário';
  DateTime? _date;
  TimeOfDay? _time;
  double _slider = 60;
  double _stepper = 4;
  bool _checked = false;
  bool _switched = true;
  String? _radio = 'Academia';

  @override
  void dispose() {
    _text.dispose();
    _search.dispose();
    _password.dispose();
    _email.dispose();
    _number.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Inputs',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Texto',
              child: Column(
                children: [
                  FitTextField(
                    controller: _text,
                    label: 'Nome',
                    hintText: 'Digite seu nome',
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitSearchField(
                    controller: _search,
                    hintText: 'Buscar exercício',
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitPasswordField(controller: _password, label: 'Senha'),
                  const SizedBox(height: FitSpacing.s12),
                  FitEmailField(controller: _email),
                  const SizedBox(height: FitSpacing.s12),
                  FitNumberField(controller: _number, label: 'Peso'),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Seleção',
              child: Column(
                children: [
                  FitDropdown<String>(
                    label: 'Nível',
                    value: _level,
                    items: const [
                      DropdownMenuItem(
                        value: 'Iniciante',
                        child: Text('Iniciante'),
                      ),
                      DropdownMenuItem(
                        value: 'Intermediário',
                        child: Text('Intermediário'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _level = value),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitDatePickerField(
                    label: 'Data',
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    value: _date,
                    onChanged: (value) => setState(() => _date = value),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitTimePickerField(
                    label: 'Horário',
                    value: _time,
                    onChanged: (value) => setState(() => _time = value),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitSlider(
                    label: 'Minutos',
                    value: _slider,
                    min: 20,
                    max: 120,
                    divisions: 10,
                    valueFormatter: (value) => '${value.round()} min',
                    onChanged: (value) => setState(() => _slider = value),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitStepper(
                    label: 'Dias por semana',
                    value: _stepper,
                    min: 1,
                    max: 7,
                    valueFormatter: (value) => value.round().toString(),
                    onChanged: (value) => setState(() => _stepper = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Controles',
              child: Column(
                children: [
                  FitCheckbox(
                    label: 'Aceito os termos',
                    value: _checked,
                    onChanged: (value) =>
                        setState(() => _checked = value ?? false),
                  ),
                  FitSwitch(
                    label: 'Notificações',
                    value: _switched,
                    onChanged: (value) => setState(() => _switched = value),
                  ),
                  FitRadio<String>(
                    label: 'Academia',
                    value: 'Academia',
                    groupValue: _radio,
                    onChanged: (value) => setState(() => _radio = value),
                  ),
                  FitRadio<String>(
                    label: 'Casa',
                    value: 'Casa',
                    groupValue: _radio,
                    onChanged: (value) => setState(() => _radio = value),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitOTPField(controller: _otp, length: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
