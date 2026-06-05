import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import '../models/country.dart'; // Unused

class ScanHistoryItem {
  final String id;
  final String brand;
  final String productId;
  final DateTime timestamp;
  final Map<String, double> prices; // Code -> Price
  
  ScanHistoryItem({
    required this.id,
    required this.brand,
    required this.productId,
    required this.timestamp,
    required this.prices,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'productId': productId,
    'timestamp': timestamp.toIso8601String(),
    'prices': prices,
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'],
      brand: json['brand'],
      productId: json['productId'],
      timestamp: DateTime.parse(json['timestamp']),
      prices: Map<String, double>.from(json['prices'] ?? {}),
    );
  }
}

class HistoryRepository {
  static const String _key = 'scan_history_v1';
  
  Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return [];
    
    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => ScanHistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addToHistory(String brand, String productId, Map<String, double> foundPrices) async {
    if (foundPrices.isEmpty) return; // Don't save empty scans
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Check if already exists recently (fuzzy logic to avoid duplicates)
    final existingIndex = history.indexWhere((h) => 
      h.brand == brand && 
      h.productId == productId &&
      h.timestamp.difference(DateTime.now()).inMinutes.abs() < 60 // Allow rescan after 1h
    );

    final newItem = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      brand: brand,
      productId: productId,
      timestamp: DateTime.now(),
      prices: foundPrices,
    );

    if (existingIndex >= 0) {
      history[existingIndex] = newItem; // Update
    } else {
      history.insert(0, newItem); // Add to top
    }
    
    // Limit to 50 items
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    await prefs.setString(_key, json.encode(history.map((e) => e.toJson()).toList()));
  }
  
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
