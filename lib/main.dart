import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const ComparaApp(),
    ),
  );
}

class ComparaApp extends StatelessWidget {
  const ComparaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComparaSites Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const MainScreen(),
    );
  }
}
