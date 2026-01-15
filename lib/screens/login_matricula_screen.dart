import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'dashboard_gestor_screen.dart';
import '../models/employee.dart';

class LoginMatriculaScreen extends StatefulWidget {
  const LoginMatriculaScreen({super.key});

  @override
  State<LoginMatriculaScreen> createState() => _LoginMatriculaScreenState();
}

class _LoginMatriculaScreenState extends State<LoginMatriculaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _matriculaController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final matricula = _matriculaController.text.trim();
    final senha = _senhaController.text;

    if (matricula.isEmpty || senha.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha matrícula e senha';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Buscar membro da comissão pela matrícula
      final doc = await _firestore.collection('comissao').doc(matricula).get();

      if (!doc.exists) {
        // Tentar login como Gestor (Employee)
        await _tenterLoginGestor(matricula, senha);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Verificar se está ativo
      if (data['ativo'] != true) {
        setState(() {
          _errorMessage = 'Acesso desativado';
          _isLoading = false;
        });
        return;
      }

      // Verificar senha
      if (data['senha'] != senha) {
        setState(() {
          _errorMessage = 'Senha incorreta';
          _isLoading = false;
        });
        return;
      }

      // Login bem-sucedido
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userMatricula: matricula,
              isSuperAdmin: data['isSuperAdmin'] == true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao fazer login: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Título
                      Image.asset(
                        'assets/images/logo.png',
                        height: 120, 
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sistema de Avaliação',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Comissão de Avaliação de Desempenho',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Campo de Matrícula
                      TextField(
                        controller: _matriculaController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Matrícula',
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.badge, size: 24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _errorMessage != null &&
                                     _matriculaController.text.isEmpty
                              ? _errorMessage
                              : null,
                        ),
                        onSubmitted: (_) => _fazerLogin(),
                      ),
                      const SizedBox(height: 20),

                      // Campo de Senha
                      TextField(
                        controller: _senhaController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.lock, size: 24),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _fazerLogin(),
                      ),

                      // Mensagem de erro
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Botão de Login
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ENTRAR',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _tenterLoginGestor(String matricula, String senha) async {
    try {
      final doc = await _firestore.collection('funcionarios').doc(matricula).get();

      if (!doc.exists) {
         setState(() {
          _errorMessage = 'Matrícula não encontrada';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final employee = Employee.fromFirestore(data, documentId: doc.id);

      if (!employee.isManager) {
        setState(() {
          _errorMessage = 'Acesso restrito a gestores e comissão';
          _isLoading = false;
        });
        return;
      }

      if (employee.password == null) {
         setState(() {
          _errorMessage = 'Senha não definida. Contate o RH.';
          _isLoading = false;
        });
        return;
      }

      if (employee.password != senha) {
        setState(() {
          _errorMessage = 'Senha incorreta';
          _isLoading = false;
        });
        return;
      }

      // Login Gestor Sucesso
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardGestorScreen(
              userMatricula: employee.id,
              userName: employee.nome,
            ),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar gestor: $e';
        _isLoading = false;
      });
    }
  }
}
