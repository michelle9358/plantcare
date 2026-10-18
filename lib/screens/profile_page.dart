import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/historico_service.dart';
import 'login_page.dart';

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

  Future<void> editarPerfil(BuildContext context) async {
    final controller = TextEditingController(text: nomeUsuario);

    final novoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Seu nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nome = controller.text.trim();

              if (nome.isNotEmpty) {
                Navigator.pop(context, nome);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (novoNome != null && novoNome.isNotEmpty) {
      alterarNome(novoNome);
      await registrarHistorico(
        'Perfil atualizado',
        detalhes: 'Nome alterado para $novoNome.',
      );
    }
  }

  void abrirConfiguracoes(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações ⚙️'),
        content: StatefulBuilder(
          builder: (context, atualizarDialogo) {
            return SwitchListTile(
              title: const Text('Modo escuro'),
              value: modoEscuro,
              onChanged: (valor) {
                alterarTema(valor);
                atualizarDialogo(() {});
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> sairDaConta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Deseja realmente sair do PlantCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu perfil 🌷',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFF8DDE5),
            child: Icon(Icons.person, size: 55, color: Color(0xFFD4758D)),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              nomeUsuario,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar perfil'),
              subtitle: const Text('Alterar seu nome'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => editarPerfil(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              subtitle: const Text('Personalize o aplicativo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => abrirConfiguracoes(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Aparência'),
              subtitle: Text(
                modoEscuro ? 'Modo escuro ativado' : 'Modo claro ativado',
              ),
              trailing: Switch(value: modoEscuro, onChanged: alterarTema),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair da conta',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => sairDaConta(context),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'PlantCare 🌱\nCuidando das suas plantas com carinho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
