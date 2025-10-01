// lib/src/widgets/input_row.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact pair of numeric input fields (Last & Current) commonly used
/// for meter readings. Validation is left to the parent Form.
class InputRow extends StatelessWidget {
  final String label;
  final String lastInitial;
  final String currentInitial;
  final ValueChanged<String> onLastChanged;
  final ValueChanged<String> onCurrentChanged;
  final String lastHint;
  final String currentHint;

  const InputRow({
    super.key,
    required this.label,
    required this.lastInitial,
    required this.currentInitial,
    required this.onLastChanged,
    required this.onCurrentChanged,
    this.lastHint = '0',
    this.currentHint = '0',
  });

  InputDecoration _dec(String text) => InputDecoration(
    labelText: text,
    hintText: text == 'Last' ? lastHint : currentHint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textStyle?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: lastInitial,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _dec('Last'),
                onChanged: onLastChanged,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter last reading';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: currentInitial,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _dec('Current'),
                onChanged: onCurrentChanged,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter current reading';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
