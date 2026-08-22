import 'package:flutter/material.dart';

import '../auth_scaffold.dart';
import 'cadastro.dart';
import 'splash_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScaffold(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(child: Image.asset('assets/images/denteagendalogo.png', width: 175)),
    const SizedBox(height: 40),
    const Text('Bem-vindo de volta!', style: TextStyle(color: Color(0xFF163B3A), fontSize: 28, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Entre para acompanhar seus cuidados odontológicos.', style: TextStyle(color: Color(0xFF5E7776), fontSize: 16, height: 1.4)),
    const SizedBox(height: 30),
    const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined))),
    const SizedBox(height: 16),
    const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline))),
    const SizedBox(height: 32),
    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A78), foregroundColor: Colors.white), child: const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)))),
    const SizedBox(height: 16),
    Center(child: TextButton(onPressed: () => openWithSplash(context, const CadastroPage()), child: const Text('Ainda não tenho uma conta'))),
  ]));
}
