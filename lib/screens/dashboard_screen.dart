import 'package:flutter/material.dart';
import 'autoavaliacao_screen.dart';
import 'avaliacao_gestor_screen.dart';
import 'central_impressao_screen.dart';
import 'config_menu_screen.dart';
import 'gestao_equipes_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          iconSize: 32,
          onPressed: () {
            // Já está na home
          },
        ),
        title: const Text(
          'Painel de Controle',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, size: 32),
            tooltip: 'Configurações',
            onSelected: (value) {
              if (value == 'equipes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestaoEquipesScreen(),
                  ),
                );
              } else if (value == 'perguntas') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfigMenuScreen(),
                  ),
                );
              } else if (value == 'sincronizar') {
                _showSyncDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'equipes',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 28),
                    SizedBox(width: 12),
                    Text('Gestão de Equipes', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'perguntas',
                child: Row(
                  children: [
                    Icon(Icons.question_answer, size: 28),
                    SizedBox(width: 12),
                    Text('Gerenciar Perguntas', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sincronizar',
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 28),
                    SizedBox(width: 12),
                    Text('Sincronizar Planilha', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 32),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Se for paisagem (landscape) - tablet horizontal
          if (isLandscape) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGiantCard(
                      context,
                      title: 'AUTOAVALIAÇÃO',
                      icon: Icons.person,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AutoavaliacaoScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildGiantCard(
                      context,
                      title: 'AVALIAÇÃO DO GESTOR',
                      icon: Icons.supervisor_account,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AvaliacaoGestorScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildGiantCard(
                      context,
                      title: 'CENTRAL DE IMPRESSÃO',
                      icon: Icons.print,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CentralImpressaoScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Se for retrato (portrait) - tablet vertical ou celular
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: _buildGiantCard(
                    context,
                    title: 'AUTOAVALIAÇÃO',
                    icon: Icons.person,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AutoavaliacaoScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: _buildGiantCard(
                    context,
                    title: 'AVALIAÇÃO DO GESTOR',
                    icon: Icons.supervisor_account,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AvaliacaoGestorScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: _buildGiantCard(
                    context,
                    title: 'CENTRAL DE IMPRESSÃO',
                    icon: Icons.print,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CentralImpressaoScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiantCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 70 : 100,
                color: color,
              ),
              SizedBox(height: isSmallScreen ? 12 : 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sincronizar Planilha',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esta função irá importar os dados da planilha Google Sheets.\n\n'
          'Deseja continuar?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sincronização em desenvolvimento',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
            child: const Text('Sincronizar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
