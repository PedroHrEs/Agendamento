import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cadastro.dart';
import 'login.dart';
import 'splash_screen.dart';
import 'Agenda.dart';
import '../widgets/app_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007A78);
    const darkTeal = Color(0xFF005C5A);
    final isLogged = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primary, darkTeal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0x26FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Seu sorriso merece cuidado.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Agende sua consulta odontológica de forma simples, rápida e segura.',
                            style: TextStyle(
                              color: Color(0xFFE4F8F6),
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Tudo o que você precisa',
                      style: TextStyle(
                        color: Color(0xFF163B3A),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organize seus cuidados odontológicos em um só lugar.',
                      style: TextStyle(color: Color(0xFF5E7776), fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    const _FeatureCard(
                      icon: Icons.event_available_rounded,
                      title: 'Agendamento facilitado',
                      description: 'Escolha o melhor dia e horário para a sua consulta.',
                    ),
                    const SizedBox(height: 14),
                    const _FeatureCard(
                      icon: Icons.medical_services_outlined,
                      title: 'Profissionais qualificados',
                      description: 'Encontre o dentista ideal para cada necessidade.',
                    ),
                    const SizedBox(height: 14),
                    const _FeatureCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Lembretes de consulta',
                      description: 'Receba avisos para não perder nenhum compromisso.',
                    ),
                    const SizedBox(height: 32),
                    if (isLogged) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AgendaPage(),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text(
                            'AGENDAR HORÁRIO',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => openWithSplash(
                            context,
                            const CadastroPage(),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text(
                            'CRIAR UMA CONTA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => openWithSplash(
                            context,
                            const LoginPage(),
                          ),
                          child: const Text(
                            'Já tenho uma conta',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8ECEA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F3F1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF007A78)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF163B3A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF5E7776),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
