import 'package:cinghy/models/account.dart';
import 'package:cinghy/models/amount.dart';

class Posting {
  final Account account;
  final Amount? amount;
  final String? comment;

  Posting({
    required this.account,
    this.amount,
    this.comment,
  });

  factory Posting.fromHledgerString(String line) {
    final parts = line.trim().split(RegExp(r'\s{2,}'));
    final accountName = parts[0].trim();
    
    Amount? amount;
    String? comment;
    
    if (parts.length > 1) {
      final secondPart = parts[1].trim();
      if (secondPart.startsWith(';')) {
        comment = secondPart.substring(1).trim();
      } else {
        amount = Amount.parse(secondPart);
      }
    }
    
    if (parts.length > 2) {
      comment = parts[2].startsWith(';') 
          ? parts[2].substring(1).trim() 
          : parts[2].trim();
    }
    
    return Posting(
      account: Account.fromString(accountName),
      amount: amount,
      comment: comment,
    );
  }

  String toHledgerString() {
    final accountStr = account.toString();
    final amountStr = amount != null ? amount.toString() : '';
    final commentStr = comment != null ? '; $comment' : '';
    
    return '$accountStr  $amountStr  $commentStr'.trim();
  }
}