import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/models/account.dart';
import 'package:cinghy/models/amount.dart';
import 'package:cinghy/models/commodity.dart';
import 'package:cinghy/models/posting.dart';
import 'package:cinghy/models/transaction.dart';
import 'package:cinghy/services/file_service.dart';
import 'package:cinghy/services/parser_service.dart';
import 'package:cinghy/widgets/account_dropdown.dart';
import 'package:cinghy/widgets/amount_input.dart';
import 'package:cinghy/widgets/posting_form_field.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({
    Key? key,
    this.transaction,
  }) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final _descriptionController = TextEditingController();
  final _payeeController = TextEditingController();
  final _commentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isCleared = false;
  List<PostingFormData> _postings = [];
  
  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Initialize with existing transaction data
      final transaction = widget.transaction!;
      _date = transaction.date;
      _descriptionController.text = transaction.description;
      _payeeController.text = transaction.payee ?? '';
      _commentController.text = transaction.comment ?? '';
      _tagsController.text = transaction.tags.join(' ');
      _isCleared = transaction.isCleared;
      
      _postings = transaction.postings.map((posting) {
        return PostingFormData(
          account: posting.account.name,
          amount: posting.amount?.value.toString() ?? '',
          commodity: posting.amount?.commodity.symbol ?? '\$',
          isNegative: posting.amount?.isNegative ?? false,
          comment: posting.comment ?? '',
        );
      }).toList();
    } else {
      // Initialize with default values for new transaction
      _date = DateTime.now();
      _postings = [
        PostingFormData(account: '', amount: '', commodity: '\$', isNegative: false),
        PostingFormData(account: '', amount: '', commodity: '\$', isNegative: true),
      ];
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _payeeController.dispose();
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<FileService>(context);
    final accounts = ParserService.extractAccounts(fileService.transactions);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTransaction(context, fileService),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Date picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_date),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            
            // Payee (optional)
            TextFormField(
              controller: _payeeController,
              decoration: const InputDecoration(
                labelText: 'Payee (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Is cleared checkbox
            CheckboxListTile(
              title: const Text('Cleared'),
              value: _isCleared,
              onChanged: (bool? value) {
                setState(() {
                  _isCleared = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16.0),
            
            // Tags (optional)
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (space separated, optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Comment (optional)
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Postings
            ..._buildPostingFields(accounts),
            
            // Add posting button
            ElevatedButton.icon(
              onPressed: _addPosting,
              icon: const Icon(Icons.add),
              label: const Text('Add Posting'),
            ),
            const SizedBox(height: 32.0),
            
            // Save button
            ElevatedButton(
              onPressed: () => _saveTransaction(context, fileService),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPostingFields(List<String> accounts) {
    final postingWidgets = <Widget>[];
    
    for (int i = 0; i < _postings.length; i++) {
      postingWidgets.add(
        PostingFormField(
          key: ValueKey('posting_$i'),
          accounts: accounts,
          initialData: _postings[i],
          onDataChanged: (data) {
            setState(() {
              _postings[i] = data;
            });
          },
          onDelete: i > 1 ? () => _deletePosting(i) : null,
        ),
      );
      postingWidgets.add(const SizedBox(height: 16.0));
    }
    
    return postingWidgets;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _addPosting() {
    setState(() {
      _postings.add(PostingFormData(
        account: '',
        amount: '',
        commodity: '\$',
        isNegative: false,
      ));
    });
  }

  void _deletePosting(int index) {
    setState(() {
      _postings.removeAt(index);
    });
  }

  Future<void> _saveTransaction(
      BuildContext context, FileService fileService) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Prepare postings
    final postings = _postings.map((data) {
      final accountName = data.account.trim();
      if (accountName.isEmpty) {
        return null;
      }
      
      Amount? amount;
      if (data.amount.isNotEmpty) {
        final amountValue = double.tryParse(data.amount) ?? 0.0;
        amount = Amount(
          value: amountValue,
          commodity: Commodity(symbol: data.commodity),
          isNegative: data.isNegative,
        );
      }
      
      return Posting(
        account: Account.fromString(accountName),
        amount: amount,
        comment: data.comment.isNotEmpty ? data.comment : null,
      );
    }).whereType<Posting>().toList(); // Filter out nulls
    
    // Create tags list
    final tags = _tagsController.text
        .split(' ')
        .where((tag) => tag.isNotEmpty)
        .toList();
    
    // Create transaction
    final transaction = Transaction(
      id: _isEditing ? widget.transaction!.id : null,
      date: _date,
      description: _descriptionController.text.trim(),
      payee: _payeeController.text.trim().isNotEmpty
          ? _payeeController.text.trim()
          : null,
      postings: postings,
      tags: tags,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      isCleared: _isCleared,
    );
    
    try {
      if (_isEditing) {
        await fileService.updateTransaction(widget.transaction!.id, transaction);
      } else {
        await fileService.addTransaction(transaction);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }

  Future<void> _deleteTransaction(
      BuildContext context, FileService fileService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await fileService.deleteTransaction(widget.transaction!.id);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }
}

class PostingFormData {
  String account;
  String amount;
  String commodity;
  bool isNegative;
  String comment;
  
  PostingFormData({
    required this.account,
    required this.amount,
    required this.commodity,
    required this.isNegative,
    this.comment = '',
  });
}