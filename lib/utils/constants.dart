class AppConstants {
  // File extensions
  static const List<String> supportedExtensions = [
    'journal',
    'ledger',
    'hledger'
  ];
  
  // Default currencies
  static const List<String> defaultCommodities = [
    '\$',
    '€',
    '£',
    '¥'
  ];
  
  // Default accounts
  static const List<String> defaultAccounts = [
    'Assets:Cash',
    'Assets:Checking',
    'Assets:Savings',
    'Expenses:Food',
    'Expenses:Transport',
    'Expenses:Utilities',
    'Income:Salary',
    'Liabilities:CreditCard'
  ];
}