import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';


class RegisterScreen extends StatefulWidget {
  final Function()? onTap;
  RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() {
    return RegisterScreenState();
  }
}

class RegisterScreenState extends State<RegisterScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      genericErrorMessage('As senhas não correspondem!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _userService.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // AuthScreen já observa authStateChanges e abre o menu.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'weak-password' => 'A senha é muito fraca, tente novamente!',
        'invalid-email' => 'Informe um email válido!',
        'email-already-in-use' => 'Email já cadastrado, efetue o login!',
        _ => 'Não foi possível registrar: ${e.code}',
      };
      genericErrorMessage(message);
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível registrar: $e');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'Por favor, preenchar os seus dados para continuar. ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                MyTextField(
                  controller: _nameController,
                  hintText: 'Nome completo',
                  icon: Icon(Icons.person_outline),
                  obscureText: false,
                  capitalization: true,
                ),
                const SizedBox(height: 15),

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

                MyTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar senha',
                  icon: Icon(Icons.shield_outlined),
                  obscureText: true,
                  capitalization: false,
                ),
                const SizedBox(height: 15),

                MyButton(
                  onPressed: _handleSignUp,
                  formKey: _formKey,
                  text: 'Registrar',
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

                //github button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: _handleGitHubSignIn,
                      imagePath: 'assets/icons/github.svg',
                      height: 70,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // already a member? login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já possui uma conta? ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Faça login',
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
