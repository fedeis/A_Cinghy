import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/services/onedrive_service.dart';

class OneDriveAuthScreen extends StatefulWidget {
  const OneDriveAuthScreen({Key? key}) : super(key: key);

  @override
  State<OneDriveAuthScreen> createState() => _OneDriveAuthScreenState();
}

class _OneDriveAuthScreenState extends State<OneDriveAuthScreen> {
  bool _isAuthenticating = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _authenticate();
  }
  
  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });
    
    try {
      final oneDriveService = Provider.of<OneDriveService>(context, listen: false);
      final success = await oneDriveService.authenticate();
      
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _isAuthenticating = false;
            _error = 'Authentication failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _error = 'Authentication error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to OneDrive'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Connect Cinghy to OneDrive',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This will allow you to access and edit your hledger files stored in OneDrive.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _authenticate,
                      child: const Text('Try Again'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _authenticate,
                  child: const Text('Connect to OneDrive'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}