import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/storage_service.dart';
import '../utils/strings.dart';

/// Lifetime statistics screen.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = Strings(settings.languageCode);
    final storage = StorageService.instance;

    final rows = <List<String>>[
      [s.get('totalGames'), '${storage.gamesPlayed}'],
      [s.get('highestScore'), '${storage.bestScore}'],
      [s.get('averageScore'), storage.averageScore.toStringAsFixed(1)],
      [s.get('blocksPlaced'), '${storage.totalBlocksPlaced}'],
      [s.get('rowsCleared'), '${storage.totalRowsCleared}'],
      [s.get('colsCleared'), '${storage.totalColsCleared}'],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.get('statistics'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) => ListTile(
          leading: const Text('📊', style: TextStyle(fontSize: 26)),
          title: Text(rows[i][0], style: const TextStyle(fontSize: 18)),
          trailing: Text(
            rows[i][1],
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
