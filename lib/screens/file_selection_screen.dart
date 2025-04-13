import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/models/file_info.dart';
import 'package:cinghy/screens/onedrive_auth_screen.dart';
import 'package:cinghy/services/file_service.dart';
import 'package:cinghy/services/onedrive_service.dart';

class FileSelectionScreen extends StatefulWidget {
  const FileSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FileSelectionScreen> createState() => _FileSelectionScreenState();
}

class _FileSelectionScreenState extends State<FileSelectionScreen> {
  List<FileInfo>? _recentFiles;
  List<FileInfo>? _oneDriveFiles;
  bool _isLoadingRecentFiles = false;
  bool _isLoadingOneDriveFiles = false;
  
  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }
  
  Future<void> _loadRecentFiles() async {
    setState(() {
      _isLoadingRecentFiles = true;
    });
    
    try {
      final fileService = Provider.of<FileService>(context, listen: false);
      final recentFiles = await fileService.getRecentFiles();
      
      setState(() {
        _recentFiles = recentFiles;
        _isLoadingRecentFiles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecentFiles = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recent files: $e')),
        );
      }
    }
  }
  
  Future<void> _loadOneDriveFiles() async {
    final oneDriveService = Provider.of<OneDriveService>(context, listen: false);
    
    if (!oneDriveService.isAuthenticated) {
      final authenticated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const OneDriveAuthScreen(),
        ),
      );
      
      if (authenticated != true) {
        return;
      }
    }
    
    setState(() {
      _isLoadingOneDriveFiles = true;
    });
    
    try {
      final files = await oneDriveService.listFiles();
      
      setState(() {
        _oneDriveFiles = files;
        _isLoadingOneDriveFiles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOneDriveFiles = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading OneDrive files: $e')),
        );
      }
    }
  }
  
  Future<void> _selectLocalFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['journal', 'ledger', 'hledger'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        final name = result.files.first.name;
        
        final fileInfo = FileInfo(
          path: path,
          name: name,
          location: FileLocation.local,
          lastModified: DateTime.now(),
        );
        
        _openFile(fileInfo);
      }
    }
  }
  
  Future<void> _createLocalFile() async {
    final fileNameController = TextEditingController();
    
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'ledger.journal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = fileNameController.text.trim();
              if (name.isNotEmpty) {
                if (!name.endsWith('.journal') && 
                    !name.endsWith('.ledger') &&
                    !name.endsWith('.hledger')) {
                  // Add default extension
                  fileNameController.text = '$name.journal';
                }
                Navigator.pop(context, fileNameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (fileName != null && fileName.isNotEmpty) {
      try {
        final fileService = Provider.of<FileService>(context, listen: false);
        final fileInfo = await fileService.createLocalFile(fileName);
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating file: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _createOneDriveFile() async {
    final oneDriveService = Provider.of<OneDriveService>(context, listen: false);
    
    if (!oneDriveService.isAuthenticated) {
      final authenticated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const OneDriveAuthScreen(),
        ),
      );
      
      if (authenticated != true) {
        return;
      }
    }
    
    final fileNameController = TextEditingController();
    
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New OneDrive File'),
        content: TextField(
          controller: fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'ledger.journal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = fileNameController.text.trim();
              if (name.isNotEmpty) {
                if (!name.endsWith('.journal') && 
                    !name.endsWith('.ledger') &&
                    !name.endsWith('.hledger')) {
                  // Add default extension
                  fileNameController.text = '$name.journal';
                }
                Navigator.pop(context, fileNameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (fileName != null && fileName.isNotEmpty) {
      try {
        final fileInfo = await oneDriveService.createFile('/Documents', fileName);
        _openFile(fileInfo);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating file: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _openFile(FileInfo fileInfo) async {
    try {
      final fileService = Provider.of<FileService>(context, listen: false);
      final oneDriveService = Provider.of<OneDriveService>(context, listen: false);
      
      await fileService.loadFile(
        fileInfo,
        oneDriveService: fileInfo.location == FileLocation.oneDrive
            ? oneDriveService
            : null,
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select File'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Local file actions
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Local Files',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('Create new local file'),
                  onTap: _createLocalFile,
                ),
                ListTile(
                  leading: const Icon(Icons.file_open),
                  title: const Text('Open local file'),
                  onTap: _selectLocalFile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          
          // OneDrive actions
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'OneDrive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('Create new OneDrive file'),
                  onTap: _createOneDriveFile,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Browse OneDrive files'),
                  onTap: _loadOneDriveFiles,
                ),
                if (_isLoadingOneDriveFiles)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_oneDriveFiles != null)
                  ..._buildFileList(_oneDriveFiles!),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Recent files
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Recent Files',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingRecentFiles)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_recentFiles == null || _recentFiles!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No recent files')),
                  )
                else
                  ..._buildFileList(_recentFiles!),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildFileList(List<FileInfo> files) {
    return files.map((file) {
      final icon = file.location == FileLocation.local
          ? Icons.description
          : Icons.cloud_queue;
      
      return ListTile(
        leading: Icon(icon),
        title: Text(file.name),
        subtitle: Text(file.location == FileLocation.local
            ? 'Local: ${file.path}'
            : 'OneDrive'),
        trailing: file.lastModified != null
            ? Text(
                '${file.lastModified!.day}/${file.lastModified!.month}/${file.lastModified!.year}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        onTap: () => _openFile(file),
      );
    }).toList();
  }
}