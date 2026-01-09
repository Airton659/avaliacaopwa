import 'package:flutter/material.dart';

class ConfigMenuScreen extends StatelessWidget {
  const ConfigMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: const Center(
        child: Text('Configurações - Em desenvolvimento'),
      ),
    );
  }
}
