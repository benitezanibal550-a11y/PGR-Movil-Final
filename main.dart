import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// Kept for compatibility with the stable Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'pages/auth_page.dart';
import 'pages/books_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  if (AppConfig.firebaseConfigured) {
    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    } catch (error) {
      startupError = error.toString();
    }
  }
  runApp(BibliotecaApp(startupError: startupError));
}

class BibliotecaApp extends StatelessWidget {
  const BibliotecaApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176A5A),
      brightness: Brightness.light,
      surface: const Color(0xFFF8F6F1),
    );
    return MaterialApp(
      title: 'Biblioteca Personal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8F6F1),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE5E9E2)),
          ),
        ),
      ),
      home: !AppConfig.firebaseConfigured || startupError != null
          ? SetupPage(error: startupError)
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SetupPage(error: snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final user = snapshot.data;
                return user == null ? const AuthPage() : BooksPage(user: user);
              },
            ),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Biblioteca Personal',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Falta configurar Firebase. Completa config.local.json y '
                  'ejecuta el comando indicado en README.md.',
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    'Error de inicio: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
