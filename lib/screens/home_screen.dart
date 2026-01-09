import 'package:flutter/material.dart';
import 'team_management_screen.dart';
import 'evaluation_selector_screen.dart';
import 'print_center_screen.dart';
import 'admin_panel_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Avaliação de Desempenho'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business, size: 120),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Empresa de Desenvolvimento de Itabira',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMenuCard(
                      context,
                      title: 'Nova Avaliação',
                      icon: Icons.assignment,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EvaluationSelectorScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Central de Impressão',
                      icon: Icons.print,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrintCenterScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Gestão de Equipes',
                      icon: Icons.group,
                      color: Colors.orange,
                      onTap: () => _showPasswordDialog(
                        context,
                        onSuccess: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeamManagementScreen(),
                          ),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Painel Administrativo',
                      icon: Icons.settings,
                      color: Colors.purple,
                      onTap: () => _showPasswordDialog(
                        context,
                        onSuccess: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPanelScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          height: 200,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordDialog(
    BuildContext context, {
    required VoidCallback onSuccess,
  }) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senha Administrativa'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Digite a senha',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (passwordController.text == 'admin123') {
              Navigator.pop(context);
              onSuccess();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar validação de senha real
              if (passwordController.text == 'admin123') {
                Navigator.pop(context);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Senha incorreta!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
