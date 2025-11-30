import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: Color(0xFF0C2D83),
        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF0C2D83),
          secondary: Color(0xFFFFC72C),
        ),

        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: GoogleFonts.merriweather(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C2D83),
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0C2D83),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0C2D83),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          labelStyle: TextStyle(color: Color(0xFF0C2D83)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0C2D83)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFFFC72C), width: 2),
          ),
        ),
      ),

      home: SplashScreen(),
    );
  }
}
