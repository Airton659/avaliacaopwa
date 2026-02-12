import 'package:flutter/material.dart';
import 'tabs/tab_impressoes_avaliacao.dart';
import 'tabs/tab_encerramento_ciclo.dart';

class CentralImpressaoScreen extends StatelessWidget {
  final int initialIndex;
  final String? initialSearch;

  const CentralImpressaoScreen({
     super.key, 
     this.initialIndex = 0,
     this.initialSearch,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
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
        body: TabBarView(
          children: [
            const TabImpressoesAvaliacao(),
            TabEncerramentoCiclo(initialSearch: initialSearch),
          ],
        ),
      ),
    );
  }
}
