import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/api_key.dart';
import '../domain/providers/keys_provider.dart';

class KeysPage extends ConsumerWidget {
  const KeysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(apiKeysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API 密钥'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(apiKeysProvider.notifier).refresh(),
          ),
        ],
      ),
      body: keysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (keys) {
          if (keys.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_off_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无 API Key', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, index) => _KeyCard(apiKey: keys[index]),
          );
        },
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final ApiKey apiKey;

  const _KeyCard({required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称 + 状态
          Row(
            children: [
              Expanded(
                child: Text(
                  apiKey.name.isEmpty ? 'Key #${apiKey.id}' : apiKey.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(
                isActive: apiKey.isActive && !apiKey.isExpired,
                isExpired: apiKey.isExpired,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Key 值
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: apiKey.key));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _maskKey(apiKey.key),
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 配额进度
          if (apiKey.quota > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('配额', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '\$${apiKey.quotaUsed.toStringAsFixed(2)} / \$${apiKey.quota.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: apiKey.quotaUsagePercent,
                minHeight: 6,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  apiKey.quotaUsagePercent > 0.9
                      ? AppTheme.error
                      : apiKey.quotaUsagePercent > 0.7
                          ? AppTheme.warning
                          : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 用量统计
          Row(
            children: [
              _UsageChip(label: '5h', count: apiKey.usage5h),
              const SizedBox(width: 8),
              _UsageChip(label: '1d', count: apiKey.usage1d),
              const SizedBox(width: 8),
              _UsageChip(label: '7d', count: apiKey.usage7d),
            ],
          ),
        ],
      ),
    );
  }

  String _maskKey(String k) {
    if (k.length <= 12) return k;
    return '${k.substring(0, 8)}...${k.substring(k.length - 4)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isExpired;

  const _StatusBadge({required this.isActive, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final color = isExpired ? AppTheme.error : isActive ? AppTheme.success : AppTheme.warning;
    final label = isExpired ? '已过期' : isActive ? '活跃' : '停用';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  final String label;
  final int count;

  const _UsageChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
