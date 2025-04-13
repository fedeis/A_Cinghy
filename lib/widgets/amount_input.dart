import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInput extends StatefulWidget {
  final String? initialValue;
  final String? initialCommodity;
  final bool initialIsNegative;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<String> onCommodityChanged;
  final ValueChanged<bool> onIsNegativeChanged;

  const AmountInput({
    Key? key,
    this.initialValue,
    this.initialCommodity = '\$',
    this.initialIsNegative = false,
    required this.onValueChanged,
    required this.onCommodityChanged,
    required this.onIsNegativeChanged,
  }) : super(key: key);

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _valueController;
  late String _commodity;
  late bool _isNegative;
  
  final List<String> _commonCommodities = ['\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.initialValue ?? '');
    _commodity = widget.initialCommodity ?? '\$';
    _isNegative = widget.initialIsNegative;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sign toggle
        ToggleButtons(
          isSelected: [!_isNegative, _isNegative],
          onPressed: (int index) {
            setState(() {
              _isNegative = index == 1;
            });
            widget.onIsNegativeChanged(_isNegative);
          },
          children: const [
            Padding(padding: EdgeInsets.all(8.0), child: Text('+')),
            Padding(padding: EdgeInsets.all(8.0), child: Text('-')),
          ],
        ),
        const SizedBox(width: 8),
        
        // Commodity selection
        DropdownButton<String>(
          value: _commodity,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _commodity = newValue;
              });
              widget.onCommodityChanged(newValue);
            }
          },
          items: _commonCommodities.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(width: 8),
        
        // Amount input field
        Expanded(
          child: TextFormField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              hintText: '0.00',
            ),
            onChanged: widget.onValueChanged,
          ),
        ),
      ],
    );
  }
}