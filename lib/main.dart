import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/sign_in.dart';
import 'screens/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lijmcwxxlnvqynpwefyb.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxpam1jd3h4bG52cXlucHdlZnliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMTAyMjMsImV4cCI6MjA3OTU4NjIyM30.l0wGaz5WBwyDvXDPgGNZ1_cPSj0EUF_sIcH6kd_0uCk',
  );

  runApp(const TraceMeApp());
}

class TraceMeApp extends StatelessWidget {
  const TraceMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'TraceMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: session == null ? const SignInScreen() : const IndexPage(),
    );
  }
}
