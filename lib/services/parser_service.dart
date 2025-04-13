import 'package:cinghy/models/transaction.dart';

class ParserService {
  // Parse hledger file content to transactions
  static List<Transaction> parseTransactions(String content) {
    final transactions = <Transaction>[];
    final lines = content.split('\n');
    
    String currentTransactionText = '';
    bool inTransaction = false;
    
    for (final line in lines) {
      // Skip comment lines and empty lines outside transactions
      if (!inTransaction && (line.trim().isEmpty || line.trim().startsWith(';'))) {
        continue;
      }
      
      // Check if this is a transaction start line (starts with a date)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(line)) {
        // If we were already in a transaction, save the previous one
        if (inTransaction && currentTransactionText.isNotEmpty) {
          transactions.add(Transaction.fromHledgerString(currentTransactionText));
        }
        
        // Start a new transaction
        currentTransactionText = line;
        inTransaction = true;
      } else if (inTransaction) {
        // Continue adding lines to the current transaction
        currentTransactionText += '\n$line';
      }
    }
    
    // Don't forget to add the last transaction
    if (inTransaction && currentTransactionText.isNotEmpty) {
      transactions.add(Transaction.fromHledgerString(currentTransactionText));
    }
    
    return transactions;
  }
  
  // Extract all unique accounts from transactions
  static List<String> extractAccounts(List<Transaction> transactions) {
    final accounts = <String>{};
    
    for (final transaction in transactions) {
      for (final posting in transaction.postings) {
        accounts.add(posting.account.name);
      }
    }
    
    return accounts.toList()..sort();
  }
}