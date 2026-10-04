import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart.dart';
import 'config.dart';
import 'repo.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const _NotConfiguredApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => Repo(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => Cart()),
      ],
      child: const OrdinaFacileApp(),
    ),
  );
}

class OrdinaFacileApp extends StatelessWidget {
  const OrdinaFacileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrdinaFacile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Mostrato quando l'APK è stato generato senza SUPABASE_URL / SUPABASE_KEY.
class _NotConfiguredApp extends StatelessWidget {
  const _NotConfiguredApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'App non ancora collegata al database.\n\n'
              'Imposta SUPABASE_URL e SUPABASE_KEY nelle variabili del repository GitHub e rigenera l\'APK.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
