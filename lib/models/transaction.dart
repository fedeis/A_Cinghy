import 'package:cinghy/models/posting.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final String? payee;
  final List<Posting> postings;
  final List<String> tags;
  final String? comment;
  final bool isCleared;

  Transaction({
    String? id,
    required this.date,
    required this.description,
    this.payee,
    required this.postings,
    this.tags = const [],
    this.comment,
    this.isCleared = false,
  }) : id = id ?? const Uuid().v4();

  factory Transaction.fromHledgerString(String txnString) {
    final lines = txnString.split('\n');
    
    // Parse the header line
    final headerLine = lines[0].trim();
    final dateMatch = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(headerLine);
    final dateStr = dateMatch?.group(0) ?? '2023-01-01';
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);
    
    // Extract if the transaction is cleared
    final isCleared = headerLine.contains('*');
    
    // Extract description and payee
    var restOfHeader = headerLine.substring(dateStr.length).trim();
    if (isCleared && restOfHeader.startsWith('*')) {
      restOfHeader = restOfHeader.substring(1).trim();
    }
    
    String description = restOfHeader;
    String? payee;
    
    if (restOfHeader.contains('|')) {
      final parts = restOfHeader.split('|');
      payee = parts[0].trim();
      description = parts.length > 1 ? parts[1].trim() : '';
    }
    
    // Extract comment if it exists
    String? comment;
    if (description.contains(';')) {
      final parts = description.split(';');
      description = parts[0].trim();
      comment = parts[1].trim();
    }
    
    // Extract tags
    final tagRegex = RegExp(r'#[a-zA-Z0-9_]+');
    final tagMatches = tagRegex.allMatches(description);
    final tags = tagMatches.map((m) => m.group(0)!.substring(1)).toList();
    
    // Clean description from tags
    description = description.replaceAll(RegExp(r'#[a-zA-Z0-9_]+'), '').trim();
    
    // Parse postings
    final postings = <Posting>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        postings.add(Posting.fromHledgerString(line));
      }
    }
    
    return Transaction(
      date: date,
      description: description,
      payee: payee,
      postings: postings,
      tags: tags,
      comment: comment,
      isCleared: isCleared,
    );
  }

  String toHledgerString() {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final clearedStr = isCleared ? ' * ' : ' ';
    final payeeStr = payee != null ? '$payee | ' : '';
    final tagsStr = tags.isEmpty ? '' : tags.map((t) => '#$t').join(' ') + ' ';
    final commentStr = comment != null ? ' ; $comment' : '';
    
    final headerLine = '$dateStr$clearedStr$payeeStr$description $tagsStr$commentStr'.trim();
    
    final postingsStr = postings.map((p) => '    ${p.toHledgerString()}').join('\n');
    
    return '$headerLine\n$postingsStr\n';
  }
}