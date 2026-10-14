import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Salva os acontecimentos da conta no Cloud Firestore.
Future<void> registrarHistorico(String acao, {String detalhes = ''}) async {
  final usuario = FirebaseAuth.instance.currentUser;
  if (usuario == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(usuario.uid)
        .collection('historico')
        .add({
      'acao': acao,
      'detalhes': detalhes,
      'data': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    // Um erro no histórico não deve impedir o uso do aplicativo.
    debugPrint('Não foi possível salvar o histórico: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PlantCareApp());
}

// MODELO DA PLANTA
class Plant {
  String nome;
  String especie;
  String rega;
  String iluminacao;

  Plant({
    required this.nome,
    required this.especie,
    required this.rega,
    required this.iluminacao,
  });
}

// APLICATIVO
class PlantCareApp extends StatefulWidget {
  const PlantCareApp({super.key});

  @override
  State<PlantCareApp> createState() => _PlantCareAppState();
}

class _PlantCareAppState extends State<PlantCareApp> {
  bool modoEscuro = false;
  String nomeUsuario = 'Michelle';

  void alterarTema(bool valor) {
    setState(() => modoEscuro = valor);
    registrarHistorico('Tema alterado', detalhes: valor ? 'Modo escuro ativado.' : 'Modo claro ativado.');
  }

  void alterarNome(String novoNome) {
    setState(() => nomeUsuario = novoNome);
    registrarHistorico('Perfil atualizado', detalhes: 'Nome de exibição alterado para $novoNome.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlantCare',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF5F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4758D),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF24191D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4758D),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,
      home: LoginPage(
        modoEscuro: modoEscuro,
        alterarTema: alterarTema,
        nomeUsuario: nomeUsuario,
        alterarNome: alterarNome,
      ),
    );
  }
}

// LOGIN
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

      await registrarHistorico('Login realizado', detalhes: 'A conta entrou no PlantCare.');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro(e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado ao entrar.'),
        ),
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
                onSubmitted: (_) => carregando ? null : entrar(),
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
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await credencial.user?.updateDisplayName(nome);
      await registrarHistorico('Conta criada', detalhes: 'Cadastro realizado para $email.');

      if (!mounted) return;

      // A conta foi criada no Firebase Authentication.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso! 🌷 Volte e entre na conta.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro(e.code))),
      );
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
                autofillHints: const [AutofillHints.newUsername, AutofillHints.email],
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

// HOME
class HomePage extends StatefulWidget {
  final bool modoEscuro;
  final Function(bool) alterarTema;
  final String nomeUsuario;
  final Function(String) alterarNome;

  const HomePage({
    super.key,
    required this.modoEscuro,
    required this.alterarTema,
    required this.nomeUsuario,
    required this.alterarNome,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paginaAtual = 0;

  final List<Plant> plantas = [
    Plant(
      nome: 'Rose',
      especie: 'Rosa',
      rega: '2 vezes por semana',
      iluminacao: 'Luz indireta',
    ),
  ];

  void adicionarPlanta(Plant planta) {
    setState(() => plantas.add(planta));
    registrarHistorico('Planta adicionada', detalhes: '${planta.nome} (${planta.especie}).');
  }

  void removerPlanta(int index) {
    final planta = plantas[index];
    setState(() => plantas.removeAt(index));
    registrarHistorico('Planta removida', detalhes: '${planta.nome} (${planta.especie}).');
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      InicioPage(plantas: plantas, nomeUsuario: widget.nomeUsuario),
      PlantasPage(
        plantas: plantas,
        adicionarPlanta: adicionarPlanta,
        removerPlanta: removerPlanta,
      ),
      HistoricoPage(plantas: plantas),
      ProfilePage(
        modoEscuro: widget.modoEscuro,
        alterarTema: widget.alterarTema,
        nomeUsuario: widget.nomeUsuario,
        alterarNome: widget.alterarNome,
      ),
    ];

    return Scaffold(
      body: paginas[paginaAtual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaAtual,
        onDestinationSelected: (index) => setState(() => paginaAtual = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Plantas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// INÍCIO
class InicioPage extends StatelessWidget {
  final List<Plant> plantas;
  final String nomeUsuario;

  const InicioPage({
    super.key,
    required this.plantas,
    required this.nomeUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PlantCare 🌷',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $nomeUsuario! 🌱',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vamos cuidar das suas plantinhas hoje?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8DDE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.water_drop, color: Color(0xFFD4758D), size: 35),
                  SizedBox(height: 10),
                  Text(
                    'Cuidados de hoje',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('Não se esqueça de verificar suas plantas! 💕'),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Minhas plantas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (plantas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Você ainda não cadastrou nenhuma planta 🌱'),
                ),
              ),
            ...plantas.map(
              (planta) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF8DDE5),
                    child: Icon(Icons.local_florist, color: Color(0xFFD4758D)),
                  ),
                  title: Text(
                    planta.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(planta.especie),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PLANTAS
class PlantasPage extends StatefulWidget {
  final List<Plant> plantas;
  final Function(Plant) adicionarPlanta;
  final Function(int) removerPlanta;

  const PlantasPage({
    super.key,
    required this.plantas,
    required this.adicionarPlanta,
    required this.removerPlanta,
  });

  @override
  State<PlantasPage> createState() => _PlantasPageState();
}

class _PlantasPageState extends State<PlantasPage> {
  final nomeController = TextEditingController();
  final especieController = TextEditingController();
  final regaController = TextEditingController();
  final iluminacaoController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    especieController.dispose();
    regaController.dispose();
    iluminacaoController.dispose();
    super.dispose();
  }

  void abrirAdicionarPlanta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova planta 🌱'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da planta',
                  prefixIcon: Icon(Icons.local_florist),
                ),
              ),
              TextField(
                controller: especieController,
                decoration: const InputDecoration(labelText: 'Espécie'),
              ),
              TextField(
                controller: regaController,
                decoration: const InputDecoration(labelText: 'Rega'),
              ),
              TextField(
                controller: iluminacaoController,
                decoration: const InputDecoration(labelText: 'Iluminação'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite o nome da planta.'),
                  ),
                );
                return;
              }

              widget.adicionarPlanta(
                Plant(
                  nome: nomeController.text.trim(),
                  especie: especieController.text.trim(),
                  rega: regaController.text.trim(),
                  iluminacao: iluminacaoController.text.trim(),
                ),
              );

              nomeController.clear();
              especieController.clear();
              regaController.clear();
              iluminacaoController.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Planta adicionada com sucesso! 🌱'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas plantas 🌷',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4758D),
        foregroundColor: Colors.white,
        onPressed: abrirAdicionarPlanta,
        child: const Icon(Icons.add),
      ),
      body: widget.plantas.isEmpty
          ? const Center(child: Text('Nenhuma planta cadastrada 🌱'))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: widget.plantas.length,
              itemBuilder: (context, index) {
                final planta = widget.plantas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF8DDE5),
                      child: Icon(
                        Icons.local_florist,
                        color: Color(0xFFD4758D),
                      ),
                    ),
                    title: Text(
                      planta.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${planta.especie}\n'
                      '💧 ${planta.rega}\n'
                      '☀️ ${planta.iluminacao}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        widget.removerPlanta(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Planta removida.'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// HISTÓRICO
class HistoricoPage extends StatefulWidget {
  final List<Plant> plantas;

  const HistoricoPage({super.key, required this.plantas});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  String? tipoCuidado;
  String? plantaSelecionada;
  final observacaoController = TextEditingController();
  bool salvando = false;

  @override
  void dispose() {
    observacaoController.dispose();
    super.dispose();
  }

  Future<void> adicionarCuidado() async {
    if (widget.plantas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma planta antes de registrar um cuidado.')),
      );
      return;
    }

    tipoCuidado ??= 'Rega';
    plantaSelecionada ??= widget.plantas.first.nome;
    observacaoController.clear();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar cuidado 🌱'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tipoCuidado,
                  decoration: const InputDecoration(labelText: 'Tipo de cuidado'),
                  items: const [
                    DropdownMenuItem(value: 'Rega', child: Text('Rega')),
                    DropdownMenuItem(value: 'Adubação', child: Text('Adubação')),
                    DropdownMenuItem(value: 'Poda', child: Text('Poda')),
                    DropdownMenuItem(value: 'Troca de vaso', child: Text('Troca de vaso')),
                    DropdownMenuItem(value: 'Exposição à luz', child: Text('Exposição à luz')),
                    DropdownMenuItem(value: 'Observação', child: Text('Observação')),
                  ],
                  onChanged: (valor) {
                    if (valor != null) {
                      setDialogState(() => tipoCuidado = valor);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: plantaSelecionada,
                  decoration: const InputDecoration(labelText: 'Planta'),
                  items: widget.plantas
                      .map((planta) => DropdownMenuItem(
                            value: planta.nome,
                            child: Text(planta.nome),
                          ))
                      .toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setDialogState(() => plantaSelecionada = valor);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: coloquei água até a terra ficar úmida.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar registro'),
            ),
          ],
        ),
      ),
    );

    if (resultado != true || !mounted) return;

    setState(() => salvando = true);
    final detalhes = 'Planta: ${plantaSelecionada ?? widget.plantas.first.nome}.'
        '${observacaoController.text.trim().isEmpty ? '' : ' Observação: ${observacaoController.text.trim()}'}';

    await registrarHistorico('Cuidado: ${tipoCuidado ?? 'Rega'}', detalhes: detalhes);

    if (!mounted) return;
    setState(() => salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuidado registrado no histórico! 🌷'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String formatarData(dynamic valor) {
    if (valor is! Timestamp) return 'Data sendo sincronizada...';
    final data = valor.toDate().toLocal();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  IconData iconePara(String acao) {
    final texto = acao.toLowerCase();
    if (texto.contains('rega')) return Icons.water_drop_outlined;
    if (texto.contains('adub')) return Icons.compost_outlined;
    if (texto.contains('planta')) return Icons.local_florist_outlined;
    if (texto.contains('perfil') || texto.contains('conta')) return Icons.person_outline;
    if (texto.contains('tema')) return Icons.palette_outlined;
    if (texto.contains('saiu') || texto.contains('logout')) return Icons.logout;
    if (texto.contains('poda')) return Icons.content_cut;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico 🌱', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: salvando ? null : adicionarCuidado,
        backgroundColor: const Color(0xFFD4758D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar cuidado'),
      ),
      body: usuario == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Entre na sua conta para visualizar o histórico.'),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuario.uid)
                  .collection('historico')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar o histórico. Confira as regras do Cloud Firestore e sua conexão.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final registros = snapshot.data?.docs ?? [];

                if (registros.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 70, color: Color(0xFFD4758D)),
                          SizedBox(height: 15),
                          Text(
                            'Seu histórico ainda está vazio 🌱',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'As ações da sua conta aparecerão aqui. Toque em “Registrar cuidado” para adicionar uma rega, adubação ou outro cuidado.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final registro = registros[index].data();
                    final acao = registro['acao'] as String? ?? 'Ação realizada';
                    final detalhes = registro['detalhes'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF8DDE5),
                          child: Icon(iconePara(acao), color: const Color(0xFFD4758D)),
                        ),
                        title: Text(acao, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (detalhes.isNotEmpty) Text(detalhes),
                              const SizedBox(height: 5),
                              Text(
                                formatarData(registro['data']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        isThreeLine: detalhes.isNotEmpty,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// PERFIL
class ProfilePage extends StatelessWidget {
  final bool modoEscuro;
  final Function(bool) alterarTema;
  final String nomeUsuario;
  final Function(String) alterarNome;

  const ProfilePage({
    super.key,
    required this.modoEscuro,
    required this.alterarTema,
    required this.nomeUsuario,
    required this.alterarNome,
  });

  void editarPerfil(BuildContext context) {
    final apelidoController = TextEditingController(text: nomeUsuario);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar perfil ✏️'),
        content: TextField(
          controller: apelidoController,
          decoration: const InputDecoration(
            labelText: 'Apelido',
            hintText: 'Digite seu apelido',
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novoNome = apelidoController.text.trim();
              if (novoNome.isNotEmpty) {
                alterarNome(novoNome);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil atualizado!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4758D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void abrirConfiguracoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RadioListTile<bool>(
              title: const Text('Modo claro ☀️'),
              value: false,
              groupValue: modoEscuro,
              onChanged: (valor) {
                if (valor != null) {
                  alterarTema(valor);
                  Navigator.pop(sheetContext);
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text('Modo escuro 🌙'),
              value: true,
              groupValue: modoEscuro,
              onChanged: (valor) {
                if (valor != null) {
                  alterarTema(valor);
                  Navigator.pop(sheetContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sairDaConta(BuildContext context) async {
    try {
      await registrarHistorico('Logout realizado', detalhes: 'A conta saiu do PlantCare.');
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            modoEscuro: modoEscuro,
            alterarTema: alterarTema,
            nomeUsuario: nomeUsuario,
            alterarNome: alterarNome,
          ),
        ),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você saiu da sua conta.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair da conta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFFF8DDE5),
              child: Icon(Icons.person, size: 60, color: Color(0xFFD4758D)),
            ),
            const SizedBox(height: 15),
            Text(
              nomeUsuario,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text('Apaixonada por plantas 🌷'),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFD4758D)),
                title: const Text(
                  'Editar perfil',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Alterar seu apelido'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => editarPerfil(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFFD4758D)),
                title: const Text(
                  'Configurações',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Tema e preferências'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => abrirConfiguracoes(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFD4758D)),
                title: const Text(
                  'Sair da conta',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Encerrar sua sessão'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => sairDaConta(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
