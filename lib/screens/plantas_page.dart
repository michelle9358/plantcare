import 'package:flutter/material.dart';

import '../models/plant.dart';

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
    nomeController.clear();
    especieController.clear();
    regaController.clear();
    iluminacaoController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar planta 🌱'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome da planta'),
              ),
              TextField(
                controller: especieController,
                decoration: const InputDecoration(labelText: 'Espécie'),
              ),
              TextField(
                controller: regaController,
                decoration: const InputDecoration(
                  labelText: 'Frequência de rega',
                  hintText: 'Ex.: 2 vezes por semana',
                ),
              ),
              TextField(
                controller: iluminacaoController,
                decoration: const InputDecoration(
                  labelText: 'Iluminação',
                  hintText: 'Ex.: Luz indireta',
                ),
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
              final nome = nomeController.text.trim();

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite o nome da planta.')),
                );
                return;
              }

              widget.adicionarPlanta(
                Plant(
                  nome: nome,
                  especie: especieController.text.trim().isEmpty
                      ? 'Não informada'
                      : especieController.text.trim(),
                  rega: regaController.text.trim().isEmpty
                      ? 'Não informada'
                      : regaController.text.trim(),
                  iluminacao: iluminacaoController.text.trim().isEmpty
                      ? 'Não informada'
                      : iluminacaoController.text.trim(),
                ),
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Planta adicionada com sucesso! 🌷'),
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
      body: widget.plantas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma planta cadastrada ainda 🌱',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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
                      'Espécie: ${planta.especie}\n'
                      'Rega: ${planta.rega}\n'
                      'Iluminação: ${planta.iluminacao}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remover planta',
                      onPressed: () {
                        widget.removerPlanta(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: abrirAdicionarPlanta,
        backgroundColor: const Color(0xFFD4758D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
