import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plant.dart';
import '../services/historico_service.dart';
import 'inicio_page.dart';
import 'plantas_page.dart';
import 'historico_page.dart';
import 'profile_page.dart';

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

  CollectionReference<Map<String, dynamic>>? get colecaoPlantas {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(usuario.uid)
        .collection('plantas');
  }

  Future<void> adicionarPlanta(Plant planta) async {
    final colecao = colecaoPlantas;

    if (colecao == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre na sua conta para salvar plantas.'),
        ),
      );
      return;
    }

    try {
      await colecao.add(planta.toMap());

      await registrarHistorico(
        'Planta adicionada',
        detalhes: '${planta.nome} (${planta.especie}).',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planta salva com sucesso! 🌷')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a planta: $erro')),
      );
    }
  }

  Future<void> removerPlanta(int index, List<Plant> listaPlantas) async {
    if (index < 0 || index >= listaPlantas.length) return;

    final planta = listaPlantas[index];
    final colecao = colecaoPlantas;

    if (colecao == null || planta.id == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível identificar a planta.')),
      );
      return;
    }

    try {
      await colecao.doc(planta.id).delete();

      await registrarHistorico(
        'Planta removida',
        detalhes: '${planta.nome} (${planta.especie}).',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planta removida com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover a planta: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Entre na sua conta para ver suas plantas.')),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(usuario.uid)
          .collection('plantas')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Erro ao carregar suas plantas.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final plantas = (snapshot.data?.docs ?? []).map((documento) {
          return Plant.fromMap(documento.data(), id: documento.id);
        }).toList();

        final paginas = [
          InicioPage(plantas: plantas, nomeUsuario: widget.nomeUsuario),
          PlantasPage(
            plantas: plantas,
            adicionarPlanta: adicionarPlanta,
            removerPlanta: (index) => removerPlanta(index, plantas),
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
            onDestinationSelected: (index) {
              setState(() => paginaAtual = index);
            },
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
      },
    );
  }
}
