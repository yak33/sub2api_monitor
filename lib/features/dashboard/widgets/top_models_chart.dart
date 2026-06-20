import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';

class TopModelsChart extends StatelessWidget {
  final List<ModelUsage> models;

  const TopModelsChart({super.key, required this.models});

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) return const SizedBox.shrink();

    final totalRequests = models.fold<int>(0, (sum, m) => sum + m.requests);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: models.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final model = entry.value;
          final percentage = totalRequests > 0 ? model.requests / totalRequests : 0.0;

          final colors = [
            AppTheme.primary,
            AppTheme.accent,
            AppTheme.info,
            AppTheme.success,
            AppTheme.warning,
          ];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    model.model,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: colors[index].withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(colors[index]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors[index],
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
