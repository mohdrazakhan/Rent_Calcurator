// lib/src/widgets/result_tile.dart
import 'package:flutter/material.dart';

/// A visual tile for displaying per-floor billing summary:
/// title (floor), units, electricity cost, optional rent part and total.
class ResultTile extends StatelessWidget {
  final String title;
  final double units;
  final double electricityCost;
  final double rentPart; // usually 0 except ground if rent included
  final IconData? icon;

  const ResultTile({
    super.key,
    required this.title,
    required this.units,
    required this.electricityCost,
    this.rentPart = 0.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final total = electricityCost + rentPart;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.12),
              child: icon == null
                  ? Text(title[0])
                  : Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${units.toStringAsFixed(2)} units • ₹ ${electricityCost.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (rentPart > 0)
                  Text(
                    'Rent: ₹ ${rentPart.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                const SizedBox(height: 6),
                Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '₹ ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
