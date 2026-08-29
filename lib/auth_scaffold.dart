import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const AuthScaffold({
    required this.child,
    this.scrollable = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
      ),
    );
  }
}
