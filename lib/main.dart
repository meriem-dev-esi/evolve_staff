import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evolve_staff/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ficrjocgrcghxrdpwbbw.supabase.co',
    publishableKey: 'sb_publishable_4iPyk0EvUvT2OfKrDbhQxA_bvOhv2P2',
  );

  runApp(const EvolveStaffApp());
}

class EvolveStaffApp extends StatelessWidget {
  const EvolveStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evolve Staff',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
      ),
      home: const LoginScreen(),
    );
  }
}
