import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/feature_account/authentication_page.dart';
import 'package:inote/pages/bottomnavbar.dart';
import 'package:inote/hive/hive_auth_box.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    Future.delayed(const Duration(milliseconds: 50), () {
      final loggedIn = HiveAuthBox.isLoggedIn();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              loggedIn ? const BottomNavBar() : const AuthenticationPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_add,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'My iNotes',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome to iNotes App',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
