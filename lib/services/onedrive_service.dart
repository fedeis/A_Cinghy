import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'package:cinghy/models/file_info.dart';

class OneDriveService extends ChangeNotifier {
  static const String _clientId = 'YOUR_CLIENT_ID'; // Replace with your client ID
  static const String _tenantId = 'common';
  static const String _redirectUrl = 'http://localhost:8080';
  static const String _authorizationEndpoint = 
      'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/authorize';
  static const String _tokenEndpoint = 
      'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token';
  static const List<String> _scopes = ['Files.ReadWrite', 'offline_access'];
  
  oauth2.Client? _client;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  
  OneDriveService() {
    _checkAuthentication();
  }
  
  // Check if user is already authenticated
  Future<void> _checkAuthentication() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final storage = FlutterSecureStorage();
      final credentials = await storage.read(key: 'onedrive_credentials');
      
      if (credentials != null) {
        final json = jsonDecode(credentials);
        final accessToken = json['access_token'];
        final refreshToken = json['refresh_token'];
        final expiration = DateTime.parse(json['expiration']);
        
        final newCredentials = oauth2.Credentials(
          accessToken,
          refreshToken: refreshToken,
          expiration: expiration,
          tokenEndpoint: Uri.parse(_tokenEndpoint),
          scopes: _scopes,
        );
        
        _client = oauth2.Client(newCredentials,
          identifier: _clientId,
          secret: '',
          onCredentialsRefreshed: _onCredentialsRefreshed,
        );
        
        _isAuthenticated = true;
      }
    } catch (e) {
      _client = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Handle refreshed credentials
  Future<void> _onCredentialsRefreshed(oauth2.Credentials credentials) async {
    final storage = FlutterSecureStorage();
    await storage.write(
      key: 'onedrive_credentials',
      value: jsonEncode({
        'access_token': credentials.accessToken,
        'refresh_token': credentials.refreshToken,
        'expiration': credentials.expiration?.toIso8601String(),
      }),
    );
  }
  
  // Authenticate with Microsoft OneDrive
  Future<bool> authenticate() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final grant = oauth2.AuthorizationCodeGrant(
        _clientId,
        Uri.parse(_authorizationEndpoint),
        Uri.parse(_tokenEndpoint),
      );
      
      final authorizationUrl = grant.getAuthorizationUrl(
        Uri.parse(_redirectUrl),
        scopes: _scopes,
      );
      
      await launchUrl(authorizationUrl, mode: LaunchMode.externalApplication);
      
      // This is where you would normally wait for a callback/redirect with the authorization code.
      // For mobile apps, this requires additional setup with a custom URL scheme.
      // For simplicity, we'll simulate a manual code entry here.
      
      // In a real app, you would use a custom URL scheme and handle the redirect.
      // The code below is simplified for demonstration purposes.
      
      // Assume we got the authorization code
      final code = await _getAuthorizationCode();
      
      if (code == null) {
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _client = await grant.handleAuthorizationCode(code);
      
      // Save credentials
      await _onCredentialsRefreshed(_client!.credentials);
      
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _client = null;
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // This method would be implemented to get the authorization code from the redirect
  // In a real app, this would be handled by intercepting the redirect URI
  Future<String?> _getAuthorizationCode() async {
    // This is a placeholder. In a real app, you would get this from the redirect.
    return null;
  }
  
  // Sign out
  Future<void> signOut() async {
    _client = null;
    _isAuthenticated = false;
    
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'onedrive_credentials');
    
    notifyListeners();
  }
  
  // List files in OneDrive
  Future<List<FileInfo>> listFiles({String folderPath = '/Documents'}) async {
    if (!_isAuthenticated || _client == null) {
      throw Exception('Not authenticated');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client!.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:$folderPath:/children'),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['value'] as List<dynamic>;
        
        return items
            .where((item) => 
                item['file'] != null && 
                (item['name'] as String).endsWith('.journal'))
            .map((item) => FileInfo(
                  path: item['parentReference']['path'] + '/' + item['name'],
                  name: item['name'],
                  location: FileLocation.oneDrive,
                  oneDriveId: item['id'],
                  lastModified: DateTime.parse(item['lastModifiedDateTime']),
                ))
            .toList();
      } else {
        throw Exception('Failed to list files: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Download file content
  Future<String> downloadFile(String fileId) async {
    if (!_isAuthenticated || _client == null) {
      throw Exception('Not authenticated');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client!.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId/content'),
      );
      
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Upload file content
  Future<void> uploadFile(String fileId, String content, String fileName) async {
    if (!_isAuthenticated || _client == null) {
      throw Exception('Not authenticated');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client!.put(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId/content'),
        body: content,
        headers: {
          'Content-Type': 'text/plain',
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new file in OneDrive
  Future<FileInfo> createFile(String folderPath, String fileName) async {
    if (!_isAuthenticated || _client == null) {
      throw Exception('Not authenticated');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client!.put(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:$folderPath/$fileName:/content'),
        body: '',
        headers: {
          'Content-Type': 'text/plain',
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        return FileInfo(
          path: json['parentReference']['path'] + '/' + json['name'],
          name: json['name'],
          location: FileLocation.oneDrive,
          oneDriveId: json['id'],
          lastModified: DateTime.parse(json['lastModifiedDateTime']),
        );
      } else {
        throw Exception('Failed to create file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}