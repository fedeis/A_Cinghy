import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinghy/models/transaction.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Find the first non-zero amount posting for display
    final displayPosting = transaction.postings.firstWhere(
      (p) => p.amount != null && p.amount!.value > 0,
      orElse: () => transaction.postings.first,
    );
    
    final amount = displayPosting.amount;
    final amountText = amount != null ? amount.toString() : '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('dd').format(transaction.date),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('E').format(transaction.date),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            DateFormat('MMM').format(transaction.date),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    amountText,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: amount != null && amount.isNegative
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              
              // Description and payee
              Text(
                transaction.description,
                style: theme.textTheme.titleMedium,
              ),
              if (transaction.payee != null && transaction.payee!.isNotEmpty)
                Text(
                  'Payee: ${transaction.payee}',
                  style: theme.textTheme.bodyMedium,
                ),
              
              // Show the first few accounts
              const SizedBox(height: 4.0),
              ...transaction.postings.take(2).map((posting) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          posting.account.toString(),
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (posting.amount != null)
                        Text(
                          posting.amount.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                );
              }).toList(),
              
              // Show a message if there are more postings
              if (transaction.postings.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${transaction.postings.length - 2} more accounts',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              
              // Tags
              if (transaction.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 4.0,
                    children: transaction.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}