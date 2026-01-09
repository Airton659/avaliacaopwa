import 'package:flutter/material.dart';

class CentralImpressaoScreen extends StatelessWidget {
  const CentralImpressaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Impressão'),
      ),
      body: const Center(
        child: Text('Central de Impressão - Em desenvolvimento'),
      ),
    );
  }
}
