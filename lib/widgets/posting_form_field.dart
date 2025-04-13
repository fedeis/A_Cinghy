import 'package:flutter/material.dart';
import 'package:cinghy/screens/transaction_form_screen.dart';
import 'package:cinghy/widgets/account_dropdown.dart';
import 'package:cinghy/widgets/amount_input.dart';

class PostingFormField extends StatefulWidget {
  final List<String> accounts;
  final PostingFormData initialData;
  final ValueChanged<PostingFormData> onDataChanged;
  final VoidCallback? onDelete;

  const PostingFormField({
    Key? key,
    required this.accounts,
    required this.initialData,
    required this.onDataChanged,
    this.onDelete,
  }) : super(key: key);

  @override
  State<PostingFormField> createState() => _PostingFormFieldState();
}

class _PostingFormFieldState extends State<PostingFormField> {
  late PostingFormData _data;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _commentController.text = _data.comment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onDataChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account field
            AccountDropdown(
              accounts: widget.accounts,
              initialValue: _data.account,
              onChanged: (value) {
                setState(() {
                  _data.account = value;
                });
                _updateData();
              },
            ),
            const SizedBox(height: 16.0),
            
            // Amount field
            AmountInput(
              initialValue: _data.amount,
              initialCommodity: _data.commodity,
              initialIsNegative: _data.isNegative,
              onValueChanged: (value) {
                setState(() {
                  _data.amount = value;
                });
                _updateData();
              },
              onCommodityChanged: (value) {
                setState(() {
                  _data.commodity = value;
                });
                _updateData();
              },
              onIsNegativeChanged: (value) {
                setState(() {
                  _data.isNegative = value;
                });
                _updateData();
              },
            ),
            const SizedBox(height: 16.0),
            
            // Comment field
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _data.comment = value;
                });
                _updateData();
              },
            ),
            
            // Delete button
            if (widget.onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}