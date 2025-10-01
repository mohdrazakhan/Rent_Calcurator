// lib/src/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill_result.dart';

class HistoryScreen extends StatelessWidget {
  static const routeName = '/history';
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final history = provider.history;

    return Scaffold(
      appBar: AppBar(title: Text('Saved Bills')),
      body: history.isEmpty
          ? Center(child: Text('No saved bills yet.'))
          : ListView.separated(
              padding: EdgeInsets.all(12),
              itemCount: history.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final BillResult r = history[idx];
                return Dismissible(
                  key: ValueKey(r.hashCode ^ idx),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.removeHistoryAt(idx);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Removed from history')),
                    );
                  },
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white,
                    title: Text(
                      'Saved bill • ₹ ${r.grandTotal.toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      '${r.adjustedUnits.length} floors • Water ${r.waterTotalUnits.toStringAsFixed(2)}u',
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // show details by pushing result-like page that uses this BillResult
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _SavedResultViewer(billResult: r),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _SavedResultViewer extends StatelessWidget {
  final BillResult billResult;
  const _SavedResultViewer({required this.billResult});

  @override
  Widget build(BuildContext context) {
    final r = billResult;
    return Scaffold(
      appBar: AppBar(title: Text('Saved bill')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'Total: ₹ ${r.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Electricity: ₹ ${r.totalElectricityCost.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Water units: ${r.waterTotalUnits.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            for (final e in r.adjustedUnits.entries) ...[
              ListTile(
                title: Text(e.key),
                subtitle: Text('${e.value.toStringAsFixed(2)} units'),
                trailing: Text(
                  '₹ ${r.electricityCostPerFloor[e.key]!.toStringAsFixed(2)}',
                ),
              ),
              Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
