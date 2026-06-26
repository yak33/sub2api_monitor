import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';
import 'top_models_chart.dart';
import 'user_ranking_widget.dart';

/// 分布概览卡片（管理员，对齐 Web 版可切换的「模型分布 / 用户消费榜」）。
///
/// 单卡片承载两个视图，顶部分段切换：每个视图 = 环形图（占比一目了然）+ 明细列表。
/// 列表复用 [TopModelsChart] / [UserRankingWidget] 的 `embedded` 模式，避免卡片套卡片。
class DistributionCard extends StatefulWidget {
  final List<ModelUsage> models;
  final List<UserRankingItem> ranking;

  const DistributionCard({super.key, required this.models, required this.ranking});

  @override
  State<DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<DistributionCard> {
  /// 0 = 模型分布，1 = 用户消费榜。
  int _tab = 0;

  // 环形图分段配色（与 TopModelsChart 行内强调色一致，便于视觉关联）。
  static const _palette = [
    AppTheme.primary,
    AppTheme.accent,
    AppTheme.info,
    AppTheme.success,
    AppTheme.warning,
  ];

  bool get _hasModels => widget.models.isNotEmpty;
  bool get _hasRanking => widget.ranking.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasModels && !_hasRanking) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    // 仅单边有数据时，强制停在该视图并隐藏切换。
    final showToggle = _hasModels && _hasRanking;
    final tab = !_hasModels ? 1 : (!_hasRanking ? 0 : _tab);
    final isModels = tab == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isModels ? '模型分布' : '用户消费榜',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const Spacer(),
              if (showToggle) 
                SizedBox(
                  width: 160,
                  child: _Toggle(tab: tab, onChanged: (v) => setState(() => _tab = v), cs: cs),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.04, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slide,
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<int>(tab),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Donut(segments: _segments(isModels), centerLabel: _centerLabel(isModels), cs: cs),
                const SizedBox(height: 18),
                Divider(color: cs.outlineVariant, height: 1),
                const SizedBox(height: 14),
                isModels
                    ? TopModelsChart(models: widget.models, embedded: true)
                    : UserRankingWidget(ranking: widget.ranking, embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 取 Top5 分段，其余聚合为「其他」（灰色），与列表 take(5) 对齐。
  List<_Segment> _segments(bool isModels) {
    final raw = isModels
        ? widget.models.map((m) => m.requests.toDouble()).toList()
        : widget.ranking.map((u) => u.cost).toList();

    final segments = <_Segment>[];
    for (var i = 0; i < raw.length && i < 5; i++) {
      segments.add(_Segment(raw[i], _palette[i % _palette.length]));
    }
    final rest = raw.skip(5).fold<double>(0, (sum, v) => sum + v);
    if (rest > 0) segments.add(_Segment(rest, Colors.grey.shade400));
    return segments;
  }

  /// 环心标签：模型视图显示总请求，消费榜显示总消费。
  ({String value, String hint}) _centerLabel(bool isModels) {
    if (isModels) {
      final total = widget.models.fold<int>(0, (s, m) => s + m.requests);
      return (value: _compact(total.toDouble()), hint: '总请求');
    }
    final total = widget.ranking.fold<double>(0, (s, u) => s + u.cost);
    return (value: '\$${_cost(total)}', hint: '总消费');
  }

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static String _cost(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(2);
  }
}

class _Segment {
  final double value;
  final Color color;
  const _Segment(this.value, this.color);
}

/// 精美分段选择控件（滑块背景物理跟随动效）。
class _Toggle extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;
  final ColorScheme cs;

  const _Toggle({required this.tab, required this.onChanged, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              // 物理跟随滑动背景
              AnimatedAlign(
                alignment: tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: width,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                ),
              ),
              // 点击区域与文本渐变
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(0),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: tab == 0 ? FontWeight.w600 : FontWeight.w500,
                            color: tab == 0 ? cs.primary : cs.onSurfaceVariant,
                          ),
                          child: const Text('模型分布'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(1),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: tab == 1 ? FontWeight.w600 : FontWeight.w500,
                            color: tab == 1 ? cs.primary : cs.onSurfaceVariant,
                          ),
                          child: const Text('消费榜'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 环形图：固定尺寸、空心、环心叠加总量标签。
class _Donut extends StatelessWidget {
  final List<_Segment> segments;
  final ({String value, String hint}) centerLabel;
  final ColorScheme cs;

  const _Donut({required this.segments, required this.centerLabel, required this.cs});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, seg) => s + seg.value);
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              startDegreeOffset: -90,
              sections: total <= 0
                  ? [PieChartSectionData(value: 1, color: cs.outlineVariant, radius: 20, showTitle: false)]
                  : segments
                      .map((seg) => PieChartSectionData(
                            value: seg.value,
                            color: seg.color,
                            radius: 22,
                            showTitle: false,
                          ))
                      .toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel.value,
                style: AppTheme.monoData(size: 18, color: cs.onSurface, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(centerLabel.hint, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
