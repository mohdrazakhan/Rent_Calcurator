// lib/src/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _rateCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final Map<int, TextEditingController> _perFloorRentCtrls = {};

  @override
  void dispose() {
    _rateCtrl.dispose();
    _rentCtrl.dispose();
    for (final c in _perFloorRentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    _rateCtrl.text = provider.ratePerUnit.toStringAsFixed(0);
    _rentCtrl.text = provider.rentAmount.toStringAsFixed(0);
    if (provider.usePerFloorRent) {
      for (var i = 0; i < provider.floorCount; i++) {
        _perFloorRentCtrls.putIfAbsent(i, () => TextEditingController());
        _perFloorRentCtrls[i]!.text = provider.perFloorRent.length > i
            ? provider.perFloorRent[i].toStringAsFixed(0)
            : '0';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Default rate per unit (₹)')),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: (v) => provider.setRatePerUnit(
                                double.tryParse(v) ?? provider.ratePerUnit,
                              ),
                              decoration: InputDecoration(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Rent section (global vs per-floor)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Use per-floor rent amounts'),
                        value: provider.usePerFloorRent,
                        onChanged: (v) => provider.setUsePerFloorRent(v),
                      ),
                      if (!provider.usePerFloorRent) ...[
                        Row(
                          children: [
                            Expanded(child: Text('Default monthly rent (₹)')),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _rentCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                onChanged: (v) => provider.setRentAmount(
                                  double.tryParse(v) ?? provider.rentAmount,
                                ),
                                decoration: InputDecoration(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: provider.rentIncludedInGround,
                              onChanged: (v) =>
                                  provider.setRentIncluded(v ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'Include rent in Ground final bill by default',
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Per-floor rent (₹)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(height: 6),
                        for (var i = 0; i < provider.floorCount; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(provider.floors[i].floorName),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    controller: _perFloorRentCtrls[i],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(hintText: '0'),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    onChanged: (v) => provider.setPerFloorRent(
                                      i,
                                      double.tryParse(v) ?? 0.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              provider.saveDefaults();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Defaults saved')),
                              );
                            },
                            child: Text('Save Defaults'),
                          ),
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              provider.clearHistory();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('History cleared')),
                              );
                            },
                            child: Text('Clear History'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Floors management
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Manage floors',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Text('${provider.floorCount} floors'),
                        ],
                      ),
                      SizedBox(height: 8),
                      for (var i = 0; i < provider.floorCount; i++)
                        ListTile(
                          title: Text(provider.floors[i].floorName),
                          subtitle: Text(
                            'Last: ${provider.floors[i].lastReading} • Current: ${provider.floors[i].currentReading}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditFloorDialog(context, provider, i);
                            },
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add floor'),
                            onPressed: () {
                              provider.addFloor();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Floor added')),
                              );
                            },
                          ),
                          SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: Icon(Icons.remove),
                            label: Text('Remove last'),
                            onPressed: provider.floorCount > 1
                                ? () {
                                    provider.removeFloor(
                                      provider.floorCount - 1,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Floor removed')),
                                    );
                                  }
                                : null,
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
      ),
    );
  }

  void _showEditFloorDialog(
    BuildContext context,
    BillProvider provider,
    int index,
  ) {
    final floor = provider.floors[index];
    final nameCtrl = TextEditingController(text: floor.floorName);
    final lastCtrl = TextEditingController(text: floor.lastReading.toString());
    final curCtrl = TextEditingController(
      text: floor.currentReading.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${floor.floorName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: lastCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Last'),
            ),
            TextField(
              controller: curCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Current'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateFloorReading(
                index: index,
                floorName: nameCtrl.text.trim(),
                lastReading:
                    double.tryParse(lastCtrl.text) ?? floor.lastReading,
                currentReading:
                    double.tryParse(curCtrl.text) ?? floor.currentReading,
              );
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
