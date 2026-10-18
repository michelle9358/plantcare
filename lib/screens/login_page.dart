import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/historico_service.dart';
import 'cadastro_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final bool modoEscuro;
  final Function(bool) alterarTema;
  final String nomeUsuario;
  final Function(String) alterarNome;

  const LoginPage({
    super.key,
    required this.modoEscuro,
    required this.alterarTema,
    required this.nomeUsuario,
    required this.alterarNome,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  String mensagemErro(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Esta conta está desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';
      case 'operation-not-allowed':
        return 'O login por e-mail e senha não está ativado no Firebase.';
      default:
        return 'Não foi possível entrar. Tente novamente.';
    }
  }

  Future<void> entrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final nomeFirebase = credencial.user?.displayName?.trim();

      if (nomeFirebase != null && nomeFirebase.isNotEmpty) {
        widget.alterarNome(nomeFirebase);
      }

      await registrarHistorico(
        'Login realizado',
        detalhes: 'A conta entrou no PlantCare.',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso! 🌷'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            modoEscuro: widget.modoEscuro,
            alterarTema: widget.alterarTema,
            nomeUsuario: (nomeFirebase != null && nomeFirebase.isNotEmpty)
                ? nomeFirebase
                : widget.nomeUsuario,
            alterarNome: widget.alterarNome,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagemErro(e.code))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado ao entrar.')),
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_florist,
                size: 90,
                color: Color(0xFFD4758D),
              ),
              const SizedBox(height: 20),
              const Text(
                'PlantCare',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4758D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Seu diário de cuidados com plantas 🌷',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 35),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
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
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!carregando) entrar();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: carregando ? null : entrar,
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
                      : const Text('Entrar', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: carregando
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroPage(
                              modoEscuro: widget.modoEscuro,
                              alterarTema: widget.alterarTema,
                              nomeUsuario: widget.nomeUsuario,
                              alterarNome: widget.alterarNome,
                            ),
                          ),
                        );
                      },
                child: const Text('Não tem uma conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
