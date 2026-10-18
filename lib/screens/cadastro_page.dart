import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/historico_service.dart';

// CADASTRO
class CadastroPage extends StatefulWidget {
  final bool modoEscuro;
  final Function(bool) alterarTema;
  final String nomeUsuario;
  final Function(String) alterarNome;

  const CadastroPage({
    super.key,
    required this.modoEscuro,
    required this.alterarTema,
    required this.nomeUsuario,
    required this.alterarNome,
  });

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool carregando = false;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  String mensagemErro(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'Digite um e-mail válido.';
      case 'email-already-in-use':
        return 'Este e-mail já possui uma conta.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';
      case 'operation-not-allowed':
        return 'Ative o login por e-mail e senha nas configurações do Firebase.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Não foi possível realizar o cadastro. Tente novamente.';
    }
  }

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      await credencial.user?.updateDisplayName(nome);
      await registrarHistorico(
        'Conta criada',
        detalhes: 'Cadastro realizado para $email.',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastro realizado com sucesso! 🌷 Volte e entre na conta.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagemErro(e.code))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado no cadastro.'),
        ),
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta 🌱')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spa, size: 75, color: Color(0xFFD4758D)),
              const SizedBox(height: 20),
              const Text(
                'Bem-vinda ao PlantCare!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4758D),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.newUsername,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: senhaController,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 6 caracteres)',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: carregando ? null : cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4758D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: carregando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cadastrar', style: TextStyle(fontSize: 18)),
                ),
              ),
              TextButton(
                onPressed: carregando ? null : () => Navigator.pop(context),
                child: const Text('Já tem uma conta? Voltar ao login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
