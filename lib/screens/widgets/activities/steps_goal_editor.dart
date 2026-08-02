import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/fit_design_system.dart';

class StepsGoalEditor extends StatefulWidget {
  const StepsGoalEditor({
    super.key,
    required this.initialGoal,
    required this.onSave,
  });

  final int initialGoal;
  final ValueChanged<int> onSave;

  @override
  State<StepsGoalEditor> createState() => _StepsGoalEditorState();
}

class _StepsGoalEditorState extends State<StepsGoalEditor> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialGoal}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1000 || value > 100000) {
      setState(() => _error = 'Informe uma meta entre 1.000 e 100.000 passos.');
      return;
    }
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitTextField(
          controller: _controller,
          label: 'Meta diária de passos',
          helperText: 'A mudança vale para os próximos registros.',
          errorText: _error,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: FitSpacing.s16),
        FitButton(
          label: 'Salvar meta',
          icon: Icons.check_rounded,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
