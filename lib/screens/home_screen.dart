import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home_screen'),
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Text('Welcome Home'),
      ),
    );
  }
}
