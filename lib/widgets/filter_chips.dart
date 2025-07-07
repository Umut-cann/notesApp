import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final List<String> categories;
  final List<String> selectedCategories;
  final Function(String) onCategorySelected;
  final VoidCallback onClearFilters;

  const FilterChips({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onCategorySelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Kategoriler chip'leri
          ...categories.map((category) {
            final isSelected = selectedCategories.contains(category);
            return _buildChip(
              context,
              category,
              isSelected,
              () => onCategorySelected(category),
            );
          }).toList(),
          
          // Filtreleri temizleme chip'i
          if (selectedCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                label: const Text('Temizle'),
                onSelected: (_) => onClearFilters(),
                backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
                avatar: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Material(
        elevation: isSelected ? 4 : 0,
        shadowColor:
            isSelected
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient:
                  isSelected
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      )
                      : null,
              color:
                  isSelected
                      ? null
                      : theme.colorScheme.surfaceVariant.withOpacity(0.7),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
