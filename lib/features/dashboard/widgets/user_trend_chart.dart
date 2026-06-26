import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/entities/dashboard_data.dart';

/// 用户用量趋势图（管理员，对齐 Web 版「最近使用 Top 12」）。
///
/// 每个用户一条折线，共享时间轴。窄屏下默认全部叠加，点击图例可「聚焦」单个用户
/// （其余淡出），并支持横向滚动以容纳密集的逐小时时间桶——这是把网页宽图搬到竖屏的关键取舍。
class UserTrendChart extends StatefulWidget {
  final UserUsageTrend trend;

  const UserTrendChart({super.key, required this.trend});

  @override
  State<UserTrendChart> createState() => _UserTrendChartState();
}

class _UserTrendChartState extends State<UserTrendChart> {
  /// 当前聚焦的用户；null 表示展示全部。
  int? _focusedUserId;

  static const _palette = <Color>[
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316),
    Color(0xFF6366F1), Color(0xFF84CC16), Color(0xFF06B6D4), Color(0xFFA855F7),
  ];

  Color _colorOf(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final t = widget.trend;
    if (t.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    final peak = t.series
        .expand((s) => s.values)
        .fold<int>(0, (m, v) => v > m ? v : m);
    final maxY = peak <= 0 ? 1.0 : peak * 1.12;

    // 时间桶较多时横向滚动；每桶预留 ~46px，保证折线不被压扁。
    final chartWidth = (t.dates.length * 46.0).clamp(MediaQuery.sizeOf(context).width - 56, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legend(cs),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: chartWidth, child: LineChart(_chartData(cs, maxY))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (var i = 0; i < widget.trend.series.length; i++)
          _LegendChip(
            label: widget.trend.series[i].name,
            color: _colorOf(i),
            active: _focusedUserId == null || _focusedUserId == widget.trend.series[i].userId,
            onTap: () => setState(() {
              final id = widget.trend.series[i].userId;
              _focusedUserId = _focusedUserId == id ? null : id;
            }),
            cs: cs,
          ),
      ],
    );
  }

  LineChartData _chartData(ColorScheme cs, double maxY) {
    final t = widget.trend;
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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (v, _) => Text(_tokens(v), style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= t.dates.length) return const SizedBox.shrink();
              final step = (t.dates.length / 8).ceil();
              if (t.dates.length > 9 && i % step != 0 && i != t.dates.length - 1) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: AxisSide.bottom,
                space: 6,
                child: Text(
                  _dateLabel(t.dates[i]),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        for (var i = 0; i < t.series.length; i++) _line(t.series[i], i),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => cs.inverseSurface,
          tooltipRoundedRadius: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (spots) => spots.map((spot) {
            final s = t.series[spot.barIndex];
            return LineTooltipItem(
              '${s.name}  ${_tokens(spot.y)}',
              TextStyle(color: _colorOf(spot.barIndex), fontWeight: FontWeight.w600, fontSize: 11),
            );
          }).toList(),
        ),
      ),
    );
  }

  LineChartBarData _line(UserTrendSeries s, int index) {
    final dimmed = _focusedUserId != null && _focusedUserId != s.userId;
    final color = _colorOf(index);
    return LineChartBarData(
      spots: [for (var i = 0; i < s.values.length; i++) FlSpot(i.toDouble(), s.values[i].toDouble())],
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: dimmed ? color.withValues(alpha: 0.08) : color,
      barWidth: dimmed ? 1 : 2,
      dotData: const FlDotData(show: false),
    );
  }

  /// 时间标签：强力解析后端时间字符串，将其格式化为紧凑的 `M/d HH:00`，兼顾日期与时间且防止重叠截断。
  String _dateLabel(String raw) {
    // 1. 尝试以 ISO/标准格式解析
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return dt.hour == 0
          ? '${dt.month}/${dt.day}'
          : '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:00';
    }

    // 2. 针对非标准空格分割格式 (例如 "2026-06-25 16:00:00") 手动解析
    try {
      final parts = raw.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length >= 3 && timeParts.length >= 1) {
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          return '$month/$day ${hour.toString().padLeft(2, '0')}:00';
        }
      }
    } catch (_) {}

    // 3. 极速降级兜底（保留尾部主要时间段）
    return raw.length > 5 ? raw.substring(raw.length - 5) : raw;
  }

  static String _tokens(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: active ? 1 : 0.4,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
