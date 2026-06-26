import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';

class TopModelsChart extends StatelessWidget {
  final List<ModelUsage> models;

  /// 嵌入模式：省略自身卡片外框，交由父容器（如 [DistributionCard]）统一包裹。
  final bool embedded;

  const TopModelsChart({super.key, required this.models, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final totalRequests = models.fold<int>(0, (sum, m) => sum + m.requests);

    final content = Column(
      children: models.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final model = entry.value;
          final percentage = totalRequests > 0 ? model.requests / totalRequests : 0.0;

          const colors = [
            AppTheme.primary,
            AppTheme.accent,
            AppTheme.info,
            AppTheme.success,
            AppTheme.warning,
          ];
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        model.model,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${_cost(model.actualCost > 0 ? model.actualCost : model.cost)}',
                      style: AppTheme.monoData(size: 12, color: color, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(model.requests)} 次 · ${_tokens(model.tokens)} tokens',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }).toList(),
    );

    return embedded
        ? content
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: content,
          );
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  String _tokens(int v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(2)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  String _cost(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }
}
