import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final PreferredSizeWidget? appBar;

  const AuthScaffold({
    required this.child,
    this.scrollable = true,
    this.appBar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
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
