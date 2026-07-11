import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class ReadyPlansFilters extends StatelessWidget {
  static const filters = [
    'Todos',
    'Recomendados',
    'Em destaque',
    'Favoritos',
    'Mais populares',
    'Novos',
    'Hipertrofia',
    'Emagrecimento',
    'Força',
    'Casa',
    'Academia',
    'Calistenia',
  ];

  final String selected;
  final ValueChanged<String> onSelected;

  const ReadyPlansFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selectedFilter = filter == selected;
          return ChoiceChip(
            label: Text(filter),
            selected: selectedFilter,
            onSelected: (_) => onSelected(filter),
            labelStyle: TextStyle(
              color: selectedFilter ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceElevated,
            side: BorderSide(
              color: selectedFilter ? AppColors.primary : AppColors.outlineSoft,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          );
        },
      ),
    );
  }
}
