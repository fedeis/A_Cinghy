class Account {
  final String name;
  final List<String> subAccounts;

  Account({required this.name, this.subAccounts = const []});

  factory Account.fromString(String name) {
    return Account(
      name: name,
      subAccounts: name.split(':'),
    );
  }

  @override
  String toString() {
    return name;
  }

  String get shortName {
    return subAccounts.isEmpty ? name : subAccounts.last;
  }
}