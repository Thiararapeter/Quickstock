import 'package:flutter/material.dart';

class ReportFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<String> filterOptions;
  final String title;

  const ReportFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filterOptions,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: filterOptions.map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (selected) {
                    if (selected) {
                      onFilterChanged(filter);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 