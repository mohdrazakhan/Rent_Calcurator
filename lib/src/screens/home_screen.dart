// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Utility to create numeric TextFormField bound to provider update on change.
  Widget _numberField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String hint = '0',
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter value';
        if (double.tryParse(v.trim()) == null) return 'Invalid number';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Room & Electricity'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'History',
            onPressed: () =>
                Navigator.pushNamed(context, HistoryScreen.routeName),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter meter readings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Fill last & current reading for each floor. Water meter is separate.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.electrical_services,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Floors list
                for (var i = 0; i < provider.floorCount; i++) ...[
                  _floorCard(context, provider, i),
                  SizedBox(height: 10),
                ],

                // Water meter card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water meter (separate)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: 'Last (water)',
                                initialValue: provider.water.lastReading
                                    .toString(),
                                onChanged: (v) => provider.setWaterReading(
                                  last: double.tryParse(v) ?? 0.0,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _numberField(
                                label: 'Current (water)',
                                initialValue: provider.water.currentReading
                                    .toString(),
                                onChanged: (v) => provider.setWaterReading(
                                  current: double.tryParse(v) ?? 0.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: 'Rate per unit (₹)',
                                initialValue: provider.ratePerUnit
                                    .toStringAsFixed(0),
                                onChanged: (v) => provider.setRatePerUnit(
                                  double.tryParse(v) ?? provider.ratePerUnit,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _numberField(
                                label: 'Monthly Rent (₹)',
                                initialValue: provider.rentAmount
                                    .toStringAsFixed(0),
                                onChanged: (v) => provider.setRentAmount(
                                  double.tryParse(v) ?? provider.rentAmount,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: provider.rentIncludedInGround,
                              onChanged: (v) =>
                                  provider.setRentIncluded(v ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'Include rent in Ground floor final bill',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 18),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.calculate),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('Calculate'),
                        ),
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          provider.computeBill(); // compute and set lastResult
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ResultScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        provider.resetReadings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Readings reset')),
                        );
                      },
                      icon: Icon(Icons.refresh),
                      tooltip: 'Reset',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add floor',
        child: Icon(Icons.add),
        onPressed: () {
          provider.addFloor(name: 'Floor ${provider.floorCount}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Added floor')));
        },
      ),
    );
  }

  Widget _floorCard(BuildContext context, BillProvider provider, int index) {
    final floor = provider.floors[index];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  floor.floorName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (provider.floorCount > 1)
                  IconButton(
                    onPressed: () {
                      provider.removeFloor(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed ${floor.floorName}')),
                      );
                    },
                    icon: Icon(Icons.delete_outline),
                    tooltip: 'Remove floor',
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Last reading',
                    initialValue: floor.lastReading.toString(),
                    onChanged: (v) => provider.updateFloorReading(
                      index: index,
                      lastReading: double.tryParse(v) ?? 0.0,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _numberField(
                    label: 'Current reading',
                    initialValue: floor.currentReading.toString(),
                    onChanged: (v) => provider.updateFloorReading(
                      index: index,
                      currentReading: double.tryParse(v) ?? 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
