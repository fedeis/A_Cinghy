import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/models/transaction.dart';
import 'package:cinghy/screens/file_selection_screen.dart';
import 'package:cinghy/screens/settings_screen.dart';
import 'package:cinghy/screens/transaction_form_screen.dart';
import 'package:cinghy/services/file_service.dart';
import 'package:cinghy/services/onedrive_service.dart';
import 'package:cinghy/widgets/transaction_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<FileService>(context);
    final oneDriveService = Provider.of<OneDriveService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(fileService.currentFile?.name ?? 'Cinghy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fileService.currentFile != null
                ? () => _refreshFile(fileService, oneDriveService)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: fileService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fileService.currentFile == null
              ? _buildNoFileView(context)
              : _buildTransactionList(context, fileService),
      floatingActionButton: fileService.currentFile != null
          ? FloatingActionButton(
              onPressed: () => _addTransaction(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildNoFileView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No file loaded',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectFile(context),
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, FileService fileService) {
    final transactions = fileService.transactions;
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No transactions found',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addTransaction(context),
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      );
    }
    
    // Group transactions by month
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final monthYear = DateFormat('MMMM yyyy').format(transaction.date);
      groupedTransactions.putIfAbsent(monthYear, () => []);
      groupedTransactions[monthYear]!.add(transaction);
    }
    
    // Sort months in reverse chronological order
    final sortedMonths = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });
    
    return ListView.builder(
      itemCount: sortedMonths.length,
      itemBuilder: (context, monthIndex) {
        final month = sortedMonths[monthIndex];
        final monthTransactions = groupedTransactions[month]!;
        
        // Sort transactions within month by date (newest first)
        monthTransactions.sort((a, b) => b.date.compareTo(a.date));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                month,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...monthTransactions.map((transaction) {
              return TransactionListItem(
                transaction: transaction,
                onTap: () => _editTransaction(context, transaction),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Future<void> _selectFile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FileSelectionScreen(),
      ),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
  }

  Future<void> _editTransaction(BuildContext context, Transaction transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: transaction,
        ),
      ),
    );
  }

  Future<void> _refreshFile(
      FileService fileService, OneDriveService oneDriveService) async {
    if (fileService.currentFile == null) return;
    
    try {
      await fileService.loadFile(
        fileService.currentFile!,
        oneDriveService: oneDriveService,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File refreshed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing file: $e')),
      );
    }
  }
}