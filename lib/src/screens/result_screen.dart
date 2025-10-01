// lib/src/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill_result.dart';

class ResultScreen extends StatelessWidget {
  static const routeName = '/result';
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final BillResult? res = provider.lastResult;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Summary'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save to history',
            onPressed: res == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.saveLastResultToHistory();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Saved to history')),
                    );
                  },
          ),
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Share (screenshot or CSV)',
            onPressed: () {
              // placeholder: implement share/export later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: res == null
          ? Center(
              child: Text('No result computed yet. Go to Home and calculate.'),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top summary card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total electricity cost',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '₹ ${res.totalElectricityCost.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Water units: ${res.waterTotalUnits.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Per-floor share: ${res.perFloorWaterShare.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Per-floor cards
                  for (final entry in res.adjustedUnits.entries) ...[
                    _floorResultCard(
                      entry.key,
                      entry.value,
                      res.electricityCostPerFloor[entry.key] ?? 0.0,
                      res.rentPerFloor != null
                          ? (res.rentPerFloor![entry.key] ?? 0.0)
                          : (res.rentIncludedInGround &&
                                entry.key == res.groundFloorName)
                          ? res.rentAmount
                          : 0.0,
                    ),
                    SizedBox(height: 10),
                  ],

                  SizedBox(height: 12),

                  // Grand totals
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('Electricity total')),
                              Text(
                                '₹ ${res.totalElectricityCost.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (res.rentPerFloor == null) ...[
                            Row(
                              children: [
                                Expanded(child: Text('Rent included (Ground)')),
                                Text(res.rentIncludedInGround ? 'Yes' : 'No'),
                              ],
                            ),
                            if (res.rentIncludedInGround) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: Text('Rent amount')),
                                  Text(
                                    '₹ ${res.rentAmount.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Total rent (all floors)'),
                                ),
                                Text(
                                  '₹ ${res.rentPerFloor!.values.fold<double>(0.0, (a, b) => a + b).toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ],
                          Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Grand total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '₹ ${res.grandTotal.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _floorResultCard(
    String title,
    double units,
    double cost,
    double rentPart,
  ) {
    final total = cost + rentPart;
    // ignore: sort_child_properties_last
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(title[0].toUpperCase()),
              backgroundColor: Colors.indigo.shade200,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    '${units.toStringAsFixed(2)} units • ₹ ${cost.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (rentPart > 0)
                  Text(
                    'Rent: ₹ ${rentPart.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12),
                  ),
                SizedBox(height: 4),
                Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '₹ ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
