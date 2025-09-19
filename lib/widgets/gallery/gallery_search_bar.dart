import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class GallerySearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(GalleryFilters) onFiltersChanged;
  final String? initialQuery;
  final GalleryFilters? initialFilters;

  const GallerySearchBar({
    super.key,
    required this.onSearch,
    required this.onFiltersChanged,
    this.initialQuery,
    this.initialFilters,
  });

  @override
  State<GallerySearchBar> createState() => _GallerySearchBarState();
}

class _GallerySearchBarState extends State<GallerySearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _hasText = widget.initialQuery?.isNotEmpty ?? false;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onSubmitted(String value) {
    widget.onSearch(value.trim());
  }

  void _onClear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onSubmitted: _onSubmitted,
        decoration: InputDecoration(
          hintText: 'Search albums and photos...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primary,
            size: 24,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                  ),
                  onPressed: _onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class GalleryFilterChips extends StatelessWidget {
  final List<FilterOption> filters;
  final Set<String> selectedFilters;
  final Function(String) onFilterToggle;

  const GalleryFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilters.contains(filter.value);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) => onFilterToggle(filter.value),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected 
                    ? AppColors.primary 
                    : Colors.grey[300]!,
              ),
              labelStyle: TextStyle(
                color: isSelected 
                    ? AppColors.primary 
                    : Colors.grey[700],
                fontWeight: isSelected 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FilterOption {
  final String label;
  final String value;
  final IconData? icon;

  const FilterOption({
    required this.label,
    required this.value,
    this.icon,
  });
}

// Predefined filter options for gallery
class GalleryFilters {
  static const List<FilterOption> albumFilters = [
    FilterOption(label: 'Semua', value: 'all'),
    FilterOption(label: 'Publik', value: 'public'),
    FilterOption(label: 'Privat', value: 'private'),
    FilterOption(label: 'Saya', value: 'mine'),
  ];

  static const List<FilterOption> photoFilters = [
    FilterOption(label: 'Terbaru', value: 'newest'),
    FilterOption(label: 'Terlama', value: 'oldest'),
    FilterOption(label: 'Terpopuler', value: 'popular'),
    FilterOption(label: 'Paling Disukai', value: 'most_liked'),
  ];
}