import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';


class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _userService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // AuthScreen já observa authStateChanges e abre o menu.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-credential' => 'Credenciais inválidas, tente novamente!',
        'invalid-email' => 'Informe um email válido!',
        'user-not-found' => 'Email não encontrado, efetue o registro!',
        'wrong-password' => 'Senha incorreta, tente novamente!',
        'user-disabled' => 'Esta conta está desativada.',
        _ => 'Não foi possível entrar: ${e.code}',
      };
      genericErrorMessage(message);
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGitHubSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _userService.signInWithGitHub();
    } on FirebaseAuthException catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar com GitHub: ${e.code}');
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar com GitHub: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void genericErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 243),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                SizedBox(
                  height: 100,
                  child: ClipOval(child: Image.asset('assets/logos/logo.png')),
                ),
                const SizedBox(height: 10),
                Text(
                  'Olá, efetue o login para continuar. ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                MyTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icon(Icons.email_outlined),
                  obscureText: false,
                  capitalization: false,
                ),
                const SizedBox(height: 15),

                MyTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  icon: Icon(Icons.lock_outline),
                  obscureText: true,
                  capitalization: false,
                ),
                const SizedBox(height: 15),

                MyButton(
                  onPressed: _handleSignIn,
                  formKey: _formKey,
                  text: 'Logar',
                ),
                if (_isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 20),

                // continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          'OU',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                //Login with github button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: _handleGitHubSignIn,
                      imagePath: 'assets/icons/github.svg',
                      height: 70,
                    )
                  ],
                ),
                const SizedBox(height: 30),

                // not a memeber ? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Novo por aqui? ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Registre-se',
                        style: TextStyle(
                            color: Color(0xffE01C2F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
