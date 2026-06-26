import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';

/// Token 使用趋势图（管理员，对齐 Web 版 TokenUsageTrend）。
///
/// 左轴为 Token 量纲，叠加四类 Token 折线（输入 / 输出 / 缓存写入 / 缓存读取）；
/// 右轴为缓存命中率（%），通过将命中率按 `rate/100 * maxY` 投影到同一坐标系实现
/// 「伪双轴」，右侧刻度再反算回百分比——fl_chart 无原生双轴，这是其惯用做法。
class TokenTrendChart extends StatelessWidget {
  final List<DailyUsage> data;

  const TokenTrendChart({super.key, required this.data});

  // 序列定义：颜色与取值器一一对应，UI 与图例共用，避免两处硬编码漂移。
  static const _series = <_SeriesSpec>[
    _SeriesSpec('输入', AppTheme.chartBlue),
    _SeriesSpec('输出', AppTheme.chartGreen),
    _SeriesSpec('缓存写入', AppTheme.chartAmber),
    _SeriesSpec('缓存读取', AppTheme.chartCyan),
  ];

  int _value(DailyUsage d, int i) => switch (i) {
        0 => d.inputTokens,
        1 => d.outputTokens,
        2 => d.cacheCreationTokens,
        _ => d.cacheReadTokens,
      };

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    // 纵轴上界取四类 Token 单点峰值，留 12% 余量；全零时兜底为 1 防止除零。
    final peak = data
        .expand((d) => [d.inputTokens, d.outputTokens, d.cacheCreationTokens, d.cacheReadTokens])
        .fold<int>(0, (m, v) => v > m ? v : m);
    final maxY = (peak <= 0 ? 1.0 : peak * 1.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          _Legend(cs: cs),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: LineChart(_chartData(context, cs, maxY))),
        ],
      ),
    );
  }

  LineChartData _chartData(BuildContext context, ColorScheme cs, double maxY) {
    return LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.4), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text(_tokens(v), style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(
              '${(v / maxY * 100).round()}%',
              style: TextStyle(fontSize: 9, color: AppTheme.chartPurple),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              // 标签过密时仅保留首尾与等距抽样点，避免互相重叠。
              final step = (data.length / 6).ceil();
              if (data.length > 7 && i % step != 0 && i != data.length - 1) {
                return const SizedBox.shrink();
              }
              final d = data[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${d.month}/${d.day}', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        for (var s = 0; s < _series.length; s++)
          LineChartBarData(
            spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), _value(data[i], s).toDouble())],
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: _series[s].color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: _series[s].color.withValues(alpha: 0.06)),
          ),
        // 缓存命中率：投影到 Token 轴，虚线以区别于量纲序列。
        LineChartBarData(
          spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].cacheHitRate / 100 * maxY)],
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.chartPurple,
          barWidth: 2,
          dashArray: const [5, 4],
          dotData: const FlDotData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => cs.inverseSurface,
          tooltipRoundedRadius: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (spots) => spots.map((spot) {
            final isRate = spot.barIndex == _series.length;
            final label = isRate ? '命中率' : _series[spot.barIndex].label;
            final color = isRate ? AppTheme.chartPurple : _series[spot.barIndex].color;
            final text = isRate ? '${data[spot.x.toInt()].cacheHitRate.toStringAsFixed(1)}%' : _tokens(spot.y);
            return LineTooltipItem(
              '$label  $text',
              TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _tokens(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _SeriesSpec {
  final String label;
  final Color color;
  const _SeriesSpec(this.label, this.color);
}

class _Legend extends StatelessWidget {
  final ColorScheme cs;
  const _Legend({required this.cs});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...TokenTrendChart._series.map((s) => (s.label, s.color, false)),
      ('命中率', AppTheme.chartPurple, true),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items.map((e) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: e.$2,
              borderRadius: BorderRadius.circular(2),
              // 命中率用虚线段示意（与图内虚线一致）
              border: e.$3 ? Border.all(color: e.$2, width: 0) : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(e.$1, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ]);
      }).toList(),
    );
  }
}
