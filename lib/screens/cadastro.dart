import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth_scaffold.dart';
import '../models/user.dart';
import '../services/user_services.dart';
import '../widgets/app_header.dart';
import 'dashboard.dart';
import 'home_page.dart';
import 'login.dart';
import 'splash_screen.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final UserService _userService = UserService();
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validações
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nome é obrigatório');
      return;
    }
    if (name.length < 3) {
      setState(() => _errorMessage = 'Nome deve ter pelo menos 3 caracteres');
      return;
    }
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
      setState(() => _errorMessage = 'Senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'As senhas não correspondem');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = UserModel(
        uid: '',
        name: name,
        email: email.toLowerCase(),
        phone: phone,
        password: '', // Senha não é armazenada no Firestore
      );

      await _userService.createUser(
        user: user,
        password: password,
      );

      if (!mounted) return;

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Fazer login automático após registrar
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String message = 'Ocorreu um erro ao cadastrar.';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este e-mail já está cadastrado.';
          break;
        case 'weak-password':
          message = 'A senha informada é muito fraca.';
          break;
        case 'invalid-email':
          message = 'Informe um e-mail válido.';
          break;
        case 'operation-not-allowed':
          message = 'O cadastro por e-mail não está habilitado no Firebase.';
          break;
        case 'network-request-failed':
          message = 'Erro de conexão. Verifique sua internet.';
          break;
        case 'too-many-requests':
          message = 'Muitas tentativas. Aguarde alguns instantes.';
          break;
        case 'invalid-credential':
          message = 'As credenciais informadas são inválidas.';
          break;
        default:
          message = 'Erro ao cadastrar: ${e.message ?? e.code}';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });

      // Mostrar SnackBar com erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String message = 'Erro ao cadastrar: $e';
      
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });

      // Mostrar SnackBar com erro genérico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        const Text('Crie sua conta', style: TextStyle(color: Color(0xFF163B3A), fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Comece a organizar seus cuidados odontológicos.', style: TextStyle(color: Color(0xFF5E7776), fontSize: 16)),
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
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Telefone (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar senha', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A78), foregroundColor: Colors.white),
            child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('CRIAR CONTA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => openWithSplash(context, const LoginPage()), child: const Text('Já tenho uma conta'))),
      ]),
    );
  }
}
