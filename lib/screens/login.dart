import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth_scaffold.dart';
import '../widgets/app_header.dart';
import 'cadastro.dart';
import 'dashboard.dart';
import 'home_page.dart';
import 'splash_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
  }

  void _redirectIfLoggedIn() {
    if (FirebaseAuth.instance.currentUser == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validações
    if (email.isEmpty) {
      setState(() => _errorMessage = 'E-mail é obrigatório');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'E-mail inválido');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Senha é obrigatória');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Senha deve ter no mínimo 6 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Sucesso no login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Erro ao fazer login';
      
      if (e.code == 'user-not-found') {
        errorMsg = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Senha incorreta';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'E-mail inválido';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'Usuário desativado';
      } else if (e.code == 'too-many-requests') {
        errorMsg = 'Muitas tentativas. Tente novamente mais tarde';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'Erro de conexão. Verifique sua internet';
      } else if (e.code == 'invalid-credential') {
        errorMsg = 'E-mail ou senha inválidos';
      } else {
        errorMsg = e.message ?? 'Erro ao fazer login';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      // Mostrar SnackBar adicional para erros críticos
      if (e.code == 'network-request-failed' || e.code == 'too-many-requests') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (e.toString().contains('network') || e.toString().contains('Connection')) {
        errorMsg = 'Erro de conexão. Verifique sua internet';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: AppHeader(
          onLogoTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
          onUserActionTap: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                (route) => false,
              );
              return;
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          },
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Image.asset('assets/images/denteagendalogo.png', width: 175)),
        const SizedBox(height: 40),
        const Text('Bem-vindo de volta!', style: TextStyle(color: Color(0xFF163B3A), fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Entre para acompanhar seus cuidados odontológicos.', style: TextStyle(color: Color(0xFF5E7776), fontSize: 16, height: 1.4)),
        const SizedBox(height: 30),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A78), foregroundColor: Colors.white),
            child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => openWithSplash(context, const CadastroPage()), child: const Text('Ainda não tenho uma conta'))),
      ]),
    );
  }
}
