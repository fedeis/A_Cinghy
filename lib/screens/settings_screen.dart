import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/screens/onedrive_auth_screen.dart';
import 'package:cinghy/services/onedrive_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oneDriveService = Provider.of<OneDriveService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'OneDrive Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    oneDriveService.isAuthenticated
                        ? 'Connected to OneDrive'
                        : 'Not connected to OneDrive',
                  ),
                  subtitle: Text(
                    oneDriveService.isAuthenticated
                        ? 'Tap to disconnect'
                        : 'Tap to connect',
                  ),
                  trailing: Icon(
                    oneDriveService.isAuthenticated
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                  ),
                  onTap: () async {
                    if (oneDriveService.isAuthenticated) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Disconnect from OneDrive'),
                          content: const Text(
                            'Are you sure you want to disconnect from OneDrive?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        await oneDriveService.signOut();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Disconnected from OneDrive'),
                            ),
                          );
                        }
                      }
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OneDriveAuthScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const ListTile(
                  title: Text('Cinghy'),
                  subtitle: Text('A Flutter app for working with hledger files'),
                ),
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Cinghy',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025',
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Cinghy is based on the Cone app and allows you to manage your hledger files on your device and OneDrive.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}