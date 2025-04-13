import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinghy/screens/home_screen.dart';
import 'package:cinghy/services/file_service.dart';
import 'package:cinghy/services/onedrive_service.dart';
import 'package:cinghy/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CinghyApp());
}

class CinghyApp extends StatelessWidget {
  const CinghyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileService()),
        ChangeNotifierProvider(create: (_) => OneDriveService()),
      ],
      child: MaterialApp(
        title: 'Cinghy',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}