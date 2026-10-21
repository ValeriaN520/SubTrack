import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();
  
  runApp(const SubTrackApp());
}

class SubTrackApp extends StatelessWidget {
  const SubTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C47FF)),
      ),
      home: const AuthScreen(),
    );
  }
}