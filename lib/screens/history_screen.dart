import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/history_repository.dart';
import '../models/brand.dart';

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
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Aucun historique", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Scans"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
               final confirm = await showDialog<bool>(
                 context: context, 
                 builder: (c) => AlertDialog(
                   title: const Text("Effacer l'historique ?"),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Non")),
                     TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Oui")),
                   ],
                 )
               );
               if (confirm == true) {
                 await _repo.clearHistory();
                 _load();
               }
            },
          )
        ],
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          final dateStr = DateFormat('dd/MM HH:mm').format(item.timestamp);
          final brand = Brand.fromKey(item.brand);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: brand.bgColor,
              child: Icon(
                brand.icon,
                color: brand.useDarkText ? Colors.black : brand.color,
                size: 20,
              ),
            ),
            title: Text("${brand.label} · #${item.productId}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Flexible(child: Text("Vu le $dateStr • ${item.prices.length} prix trouvés")),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onRestore(item),
          );
        },
      ),
    );
  }
}
