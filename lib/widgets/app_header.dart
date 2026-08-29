import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.onLogoTap,
    required this.onUserActionTap,
    super.key,
  });

  final VoidCallback onLogoTap;
  final VoidCallback onUserActionTap;

  String _getInitial() {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim()[0].toUpperCase();
    }

    if (user?.email != null && user!.email!.trim().isNotEmpty) {
      return user.email!.trim()[0].toUpperCase();
    }

    return 'L';
  }

  @override
  Widget build(BuildContext context) {
    final isLogged = FirebaseAuth.instance.currentUser != null;
    final primary = const Color(0xFF007A78);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14007A78),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onLogoTap,
            child: Image.asset(
              'assets/images/denteagendalogo.png',
              width: 118,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onUserActionTap,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLogged ? primary : const Color(0xFFE3F3F1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLogged
                    ? Text(
                        _getInitial(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(
                        Icons.login_rounded,
                        color: Color(0xFF007A78),
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
