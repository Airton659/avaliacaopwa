import 'package:flutter/material.dart';
import 'autoavaliacao_screen.dart';
import 'avaliacao_gestor_screen.dart';
import 'central_impressao_screen.dart';
import 'config_menu_screen.dart';
import 'gestao_equipes_screen.dart';
import 'trocar_senha_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signature_registration_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userMatricula;
  final bool isSuperAdmin;

  const DashboardScreen({
    super.key,
    required this.userMatricula,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
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
              } else if (value == 'comissao') {
                Navigator.pushNamed(context, '/gerenciar-comissao');
              } else if (value == 'senha') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrocarSenhaScreen(
                      userMatricula: userMatricula,
                      collection: 'comissao',
                      isSuperAdmin: isSuperAdmin,
                    ),
                  ),
                );
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
              if (isSuperAdmin)
                const PopupMenuItem(
                  value: 'comissao',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 28),
                      SizedBox(width: 12),
                      Text('Gerenciar Comissão', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
               const PopupMenuItem(
                 value: 'senha',
                 child: Row(
                   children: [
                     Icon(Icons.lock_reset, size: 28),
                     SizedBox(width: 12),
                     Text('Alterar Senha', style: TextStyle(fontSize: 16)),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // PRESIDENTE: Card de Assinatura (Landscape)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('comissao').doc(userMatricula).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null || data['isPresident'] != true) return const SizedBox.shrink();

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: InkWell(
                          onTap: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignatureRegistrationScreen(userId: userMatricula),
                                ),
                              );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade700, Colors.amber.shade900],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.shade700.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user, color: Colors.white, size: 32),
                                SizedBox(width: 16),
                                Text(
                                  'ÁREA DA PRESIDÊNCIA: REGISTRAR ASSINATURA OFICIAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.arrow_forward_ios, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 300,
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
                                  builder: (context) => AutoavaliacaoScreen(
                                    userMatricula: userMatricula,
                                    isComissao: true,
                                  ),
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
                                  builder: (context) => AvaliacaoGestorScreen(
                                    userMatricula: userMatricula,
                                    isComissao: true,
                                  ),
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
                // PRESIDENTE: Card de Assinatura
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('comissao').doc(userMatricula).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null || data['isPresident'] != true) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignatureRegistrationScreen(userId: userMatricula),
                              ),
                            );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade700, Colors.amber.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.shade700.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user, color: Colors.white, size: 32),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ÁREA DA PRESIDÊNCIA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'REGISTRAR ASSINATURA OFICIAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: isLandscape ? 20 : 18,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

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
                          builder: (context) => AutoavaliacaoScreen(
                            userMatricula: userMatricula,
                            isComissao: true,
                          ),
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
                          builder: (context) => AvaliacaoGestorScreen(
                            userMatricula: userMatricula,
                            isComissao: true,
                          ),
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
}
