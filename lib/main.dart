import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://ifesqbujlgzjzzvojrnb.supabase.co/rest/v1/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlmZXNxYnVqbGd6anp6dm9qcm5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxOTAyNjUsImV4cCI6MjA5NDc2NjI2NX0.hVz8fkiWCF_OX3ahqzyp0tG81kzbYR7sgJ7FscCCXoU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      //  theme:
      //    home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
