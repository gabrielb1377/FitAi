import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ReadyPlansSearch extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const ReadyPlansSearch({super.key, required this.onChanged});

  @override
  State<ReadyPlansSearch> createState() => _ReadyPlansSearchState();
}

class _ReadyPlansSearchState extends State<ReadyPlansSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        0,
        FitSpacing.s20,
        FitSpacing.s12,
      ),
      child: FitSearchField(
        controller: _controller,
        hintText: 'Buscar plano',
        onChanged: widget.onChanged,
      ),
    );
  }
}
