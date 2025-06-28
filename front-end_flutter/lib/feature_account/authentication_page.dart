import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/pages/bottomnavbar.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController loginUsernameController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final TextEditingController regUsernameController = TextEditingController();
  final TextEditingController regEmailController = TextEditingController();
  final TextEditingController regPasswordController = TextEditingController();
  final TextEditingController regConfirmController = TextEditingController();

  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerKey = GlobalKey<FormState>();

  bool _isLogin = true;

  void _switchPage() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _onLogin() async {
    if (_loginKey.currentState!.validate()) {
      final username = loginUsernameController.text;
      final password = loginPasswordController.text;

      final localUsers = HiveAuthBox.getAllUsers();
      final userExists = localUsers.any((user) => user.username == username);

      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account not found.')),
        );
        HiveAuthBox.login(username, password);
        return;
      }

      bool success = await HiveSyncManager().ensureUserRegisteredAndLoggedIn(
        username: username,
        password: password,
        email: '',
      );

      if (success) {
        await HiveAuthBox.setActiveUsername(username);
        await HiveAuthBox.setActiveUserPassword(password);
        await HiveAuthBox.setLoggedIn(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBar()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid credentials or not registered!')),
        );
      }
    }
  }

  void _onRegister() async {
    if (_registerKey.currentState!.validate()) {
      bool success = await HiveSyncManager().ensureUserRegisteredAndLoggedIn(
        username: regUsernameController.text,
        password: regPasswordController.text,
        email: regEmailController.text,
      );
      if (success) {
        await HiveAuthBox.setActiveUsername(regUsernameController.text);
        await HiveAuthBox.setActiveUserPassword(regPasswordController.text);
        await HiveAuthBox.setActiveUserEmail(regEmailController.text);
        await HiveAuthBox.setLoggedIn(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBar()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigoAccent.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.indigoAccent,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLogin ? _buildLogin() : _buildRegister(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Form(
      key: _loginKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Login",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent.shade700,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: loginUsernameController,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? "Username required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: loginPasswordController,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Password required";
              if (v.length < 8) return "Min 8 characters";
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onLogin,
              child: Text(
                "Login",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _switchPage,
            child: Text(
              "Don't have an account? Register",
              style: GoogleFonts.poppins(color: Colors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return Form(
      key: _registerKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Register",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent.shade700,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: regUsernameController,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? "Username required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: regEmailController,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return "Email required";
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(v)) return "Invalid email";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: regPasswordController,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Password required";
              if (v.length < 8) return "Min 8 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: regConfirmController,
            decoration: const InputDecoration(
              labelText: "Confirm Password",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Confirmation required";
              if (v != regPasswordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onRegister,
              child: Text(
                "Register",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _switchPage,
            child: Text(
              "Already have an account? Login",
              style: GoogleFonts.poppins(color: Colors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }
}
