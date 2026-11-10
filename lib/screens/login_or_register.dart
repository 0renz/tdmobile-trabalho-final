import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() {
    return LoginOrRegisterScreenState();
  }
}

class LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // initially show login Page
  bool showLoginScreen = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginScreen) {
      return LoginScreen(
        onTap: togglePages,
      );
    } else {
      return RegisterScreen(
        onTap: togglePages,
      );
    }
  }
}
