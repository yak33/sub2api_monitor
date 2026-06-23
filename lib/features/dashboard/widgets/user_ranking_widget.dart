import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';

/// 用户消费排行榜组件（管理员专属）。
///
/// 前三名用奖牌色高亮，其余用序号排列。展示消费金额、请求数和 Token 数。
class UserRankingWidget extends StatelessWidget {
  final List<UserRankingItem> ranking;

  const UserRankingWidget({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final maxCost = ranking.first.cost > 0 ? ranking.first.cost : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: ranking.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _RankingRow(
            rank: index + 1,
            item: item,
            maxCost: maxCost,
            cs: cs,
          );
        }).toList(),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final UserRankingItem item;
  final double maxCost;
  final ColorScheme cs;

  const _RankingRow({
    required this.rank,
    required this.item,
    required this.maxCost,
    required this.cs,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return AppTheme.warning; // 金色
      case 2:
        return AppTheme.info; // 银色偏蓝
      case 3:
        return AppTheme.accent; // 铜色偏橙
      default:
        return cs.onSurfaceVariant;
    }
  }

  IconData get _rankIcon {
    switch (rank) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final barWidth = maxCost > 0 ? (item.cost / maxCost).clamp(0.05, 1.0) : 0.05;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 排名徽章
          SizedBox(
            width: 32,
            child: isTop3
                ? Icon(_rankIcon, size: 22, color: _rankColor)
                : Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // 用户名 + 请求数
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isTop3 ? FontWeight.w600 : FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(item.requests)} 次 · ${_tokens(item.tokens)} tokens',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 消费条 + 金额
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_cost(item.cost)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isTop3 ? _rankColor : cs.primary,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: barWidth,
                    minHeight: 3,
                    backgroundColor: _rankColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(_rankColor.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
