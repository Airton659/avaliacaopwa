import 'package:flutter/material.dart';
import 'tabs/tab_impressoes_avaliacao.dart';
import 'tabs/tab_encerramento_ciclo.dart';

class CentralImpressaoScreen extends StatelessWidget {
  const CentralImpressaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Central de Impressão'),
          backgroundColor: Colors.green.shade700,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.print), text: 'Documentos de Avaliação'),
              Tab(icon: Icon(Icons.flag), text: 'Encerramento de Ciclo'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            TabImpressoesAvaliacao(),
            TabEncerramentoCiclo(),
          ],
        ),
      ),
    );
  }
}
