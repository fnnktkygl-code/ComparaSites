import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/history_repository.dart';
import '../models/brand.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final Function(ScanHistoryItem) onRestore;

  const HistoryScreen({super.key, required this.onRestore});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repo = HistoryRepository();
  List<ScanHistoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getHistory();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.mutedText(context)),
            const SizedBox(height: 16),
            Text(s.noHistory, style: TextStyle(color: AppTheme.subtleText(context))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(s.myScans),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(s.clearConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.no)),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(s.yes)),
                  ],
                ),
              );
              if (confirm == true) {
                await _repo.clearHistory();
                _load();
              }
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF1E2D47) : null),
        itemBuilder: (context, index) {
          final item = _items[index];
          final dateStr = DateFormat('dd/MM HH:mm').format(item.timestamp);
          final brand = Brand.fromKey(item.brand);

          return ListTile(
            tileColor: AppTheme.surfaceColor(context),
            leading: CircleAvatar(
              backgroundColor: brand.bgColor,
              child: Icon(
                brand.icon,
                color: brand.useDarkText ? Colors.black : brand.color,
                size: 20,
              ),
            ),
            title: Text(
              '${brand.label} · #${item.productId}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: brand.bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    brand.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: brand.useDarkText ? Colors.black : brand.color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${s.seenOn} $dateStr • ${item.prices.length} ${s.pricesFound}',
                    style: TextStyle(color: AppTheme.subtleText(context)),
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: AppTheme.subtleText(context)),
            onTap: () => widget.onRestore(item),
          );
        },
      ),
    );
  }
}
