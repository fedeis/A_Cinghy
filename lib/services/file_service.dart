import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinghy/models/file_info.dart';
import 'package:cinghy/models/transaction.dart';
import 'package:cinghy/services/parser_service.dart';
import 'package:cinghy/services/onedrive_service.dart';

// Import json library
import 'dart:convert' as json;

class FileService extends ChangeNotifier {
  FileInfo? _currentFile;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  
  FileInfo? get currentFile => _currentFile;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  
  // Get the list of recently used files
  Future<List<FileInfo>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final recentFilesJson = prefs.getStringList('recentFiles') ?? [];
    
    return recentFilesJson
        .map((json) => FileInfo.fromJson(Map<String, dynamic>.from(
            Map<String, dynamic>.from(
                Map.castFrom<dynamic, dynamic, String, dynamic>(
                    jsonDecode(json) as Map)))))
        .toList();
  }
  
  // Save a file to the list of recently used files
  Future<void> addToRecentFiles(FileInfo fileInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final recentFiles = await getRecentFiles();
    
    // Remove if already exists
    recentFiles.removeWhere((file) => 
        file.path == fileInfo.path && file.location == fileInfo.location);
    
    // Add to the beginning of the list
    recentFiles.insert(0, fileInfo);
    
    // Keep only the most recent 10 files
    final recentFilesToSave = recentFiles.take(10).toList();
    
    await prefs.setStringList('recentFiles', 
        recentFilesToSave.map((file) => jsonEncode(file.toJson())).toList());
  }
  
  // Load file content
  Future<void> loadFile(FileInfo fileInfo, {OneDriveService? oneDriveService}) async {
    _isLoading = true;
    notifyListeners();
    
    String fileContent = '';
    
    try {
      if (fileInfo.location == FileLocation.local) {
        final file = File(fileInfo.path);
        fileContent = await file.readAsString();
      } else if (fileInfo.location == FileLocation.oneDrive && oneDriveService != null) {
        fileContent = await oneDriveService.downloadFile(fileInfo.oneDriveId!);
      }
      
      _transactions = ParserService.parseTransactions(fileContent);
      _currentFile = fileInfo;
      
      // Add to recent files
      await addToRecentFiles(fileInfo);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save transactions to file
  Future<void> saveFile({OneDriveService? oneDriveService}) async {
    if (_currentFile == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final fileContent = _transactions.map((t) => t.toHledgerString()).join('\n');
      
      if (_currentFile!.location == FileLocation.local) {
        final file = File(_currentFile!.path);
        await file.writeAsString(fileContent);
      } else if (_currentFile!.location == FileLocation.oneDrive && oneDriveService != null) {
        await oneDriveService.uploadFile(
          _currentFile!.oneDriveId!, 
          fileContent,
          _currentFile!.name
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new file
  Future<FileInfo> createLocalFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    
    final file = File(path);
    if (!await file.exists()) {
      await file.create();
    }
    
    final fileInfo = FileInfo(
      path: path,
      name: fileName,
      location: FileLocation.local,
      lastModified: DateTime.now(),
    );
    
    _currentFile = fileInfo;
    _transactions = [];
    
    await addToRecentFiles(fileInfo);
    notifyListeners();
    
    return fileInfo;
  }
  
  // Add a transaction
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await saveFile();
    notifyListeners();
  }
  
  // Update a transaction
  Future<void> updateTransaction(String id, Transaction updatedTransaction) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = updatedTransaction;
      await saveFile();
      notifyListeners();
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await saveFile();
    notifyListeners();
  }
}

// Helper function to decode JSON safely
dynamic jsonDecode(String source) {
  return const JsonDecoder().convert(source);
}

// Helper function to encode object to JSON
String jsonEncode(Object? object) {
  return const JsonEncoder().convert(object);
}

class JsonDecoder {
  const JsonDecoder();
  
  dynamic convert(String source) {
    return json.jsonDecode(source);
  }
}

class JsonEncoder {
  const JsonEncoder();
  
  String convert(Object? object) {
    return json.jsonEncode(object);
  }
}

