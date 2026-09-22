import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'nav/nav.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gdxepzlxzlzjrkxqpqwo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeGVwemx4emx6anJreHFwcXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4ODU0NjMsImV4cCI6MjA2NzQ2MTQ2M30.--UZamnWbyCmxZ6GC-An8aw_mwzZ-SMpNTANSf-kWWM',
  );

  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {  
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}