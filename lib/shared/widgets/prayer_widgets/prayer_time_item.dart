import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';

class PrayerTimeItem extends StatelessWidget {
  final String name;
  final String formattedTime;
  final bool isNext;

  const PrayerTimeItem({
    Key? key,
    required this.name,
    required this.formattedTime,
    required this.isNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNext ? AppColors.primary : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.access_time,
                color: isNext ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: isNext ? AppColors.primary : Colors.black,
              ),
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}