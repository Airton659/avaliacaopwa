import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/password_helper.dart';
import 'dashboard_screen.dart';
import 'dashboard_gestor_screen.dart';

class TrocarSenhaScreen extends StatefulWidget {
  final String userMatricula;
  final String collection; // 'comissao' ou 'funcionarios'
  final bool isFirstAccess;
  final bool isSuperAdmin; // Para redirecionamento correto
  final String? userName; // Para gestores

  const TrocarSenhaScreen({
    super.key,
    required this.userMatricula,
    required this.collection,
    this.isFirstAccess = false,
    this.isSuperAdmin = false,
    this.userName,
  });

  @override
  State<TrocarSenhaScreen> createState() => _TrocarSenhaScreenState();
}

class _TrocarSenhaScreenState extends State<TrocarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaNovaController = TextEditingController();
  final _senhaConfirmarController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _senhaNovaController.dispose();
    _senhaConfirmarController.dispose();
    super.dispose();
  }

  Future<void> _trocarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaNovaController.text != _senhaConfirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.userMatricula)
          .update({
        'senha': widget.collection == 'comissao' 
            ? PasswordHelper.hashPassword(_senhaNovaController.text)
            : null, // Comissao usa 'senha', funcionarios usa 'password'
        'password': widget.collection == 'funcionarios'
            ? PasswordHelper.hashPassword(_senhaNovaController.text)
            : null,
        'isFirstAccess': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso!'), backgroundColor: Colors.green),
      );

      if (widget.isFirstAccess) {
        // Redirecionar para o dashboard apropriado
        if (widget.collection == 'comissao') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userMatricula: widget.userMatricula,
                isSuperAdmin: widget.isSuperAdmin,
              ),
            ),
          );
        } else {
             Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardGestorScreen(
                userMatricula: widget.userMatricula,
                userName: widget.userName ?? '',
              ),
            ),
          );
        }
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar senha: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir Nova Senha'),
        automaticallyImplyLeading: !widget.isFirstAccess, // Esconde voltar se for primeiro acesso
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstAccess)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Para sua segurança, defina uma nova senha no seu primeiro acesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                TextFormField(
                  controller: _senhaNovaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a nova senha';
                    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaConfirmarController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirme a senha';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _trocarSenha,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Salvar Senha', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
