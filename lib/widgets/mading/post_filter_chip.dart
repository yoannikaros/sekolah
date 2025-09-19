import 'package:flutter/material.dart';

class PostFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  
  const PostFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue[600] 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.blue[600]! 
                : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? Colors.white 
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : Colors.grey[700],
                fontWeight: isSelected 
                    ? FontWeight.bold 
                    : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}