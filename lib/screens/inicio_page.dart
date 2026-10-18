import 'package:flutter/material.dart';

import '../models/plant.dart';

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
