import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plant.dart';
import '../services/historico_service.dart';

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

  final List<String> tiposCuidado = [
    'Rega',
    'Adubação',
    'Poda',
    'Troca de vaso',
    'Limpeza das folhas',
    'Outro',
  ];

  @override
  void dispose() {
    observacaoController.dispose();
    super.dispose();
  }

  Future<void> adicionarCuidado() async {
    if (widget.plantas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre uma planta antes de registrar cuidados.'),
        ),
      );
      return;
    }

    tipoCuidado = tiposCuidado.first;
    plantaSelecionada = widget.plantas.first.nome;
    observacaoController.clear();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, atualizarDialogo) => AlertDialog(
          title: const Text('Registrar cuidado 🌱'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tipoCuidado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de cuidado',
                  ),
                  items: tiposCuidado.map((tipo) {
                    return DropdownMenuItem(value: tipo, child: Text(tipo));
                  }).toList(),
                  onChanged: (valor) {
                    atualizarDialogo(() {
                      tipoCuidado = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: plantaSelecionada,
                  decoration: const InputDecoration(labelText: 'Planta'),
                  items: widget.plantas.map((planta) {
                    return DropdownMenuItem(
                      value: planta.nome,
                      child: Text(planta.nome),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    atualizarDialogo(() {
                      plantaSelecionada = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Conte como está a planta...',
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
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true ||
        tipoCuidado == null ||
        plantaSelecionada == null ||
        !mounted) {
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final observacao = observacaoController.text.trim();

      final detalhes = observacao.isEmpty
          ? 'Planta: $plantaSelecionada'
          : 'Planta: $plantaSelecionada. Observação: $observacao';

      await registrarHistorico('Cuidado: $tipoCuidado', detalhes: detalhes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuidado registrado com sucesso! 🌷')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o cuidado: $erro')),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  String formatarData(dynamic valor) {
    if (valor is Timestamp) {
      final data = valor.toDate().toLocal();
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final hora = data.hour.toString().padLeft(2, '0');
      final minuto = data.minute.toString().padLeft(2, '0');

      return '$dia/$mes/${data.year} às $hora:$minuto';
    }

    return 'Data não disponível';
  }

  IconData iconePara(String acao) {
    final texto = acao.toLowerCase();

    if (texto.contains('rega')) {
      return Icons.water_drop;
    }
    if (texto.contains('adub')) {
      return Icons.compost;
    }
    if (texto.contains('pod')) {
      return Icons.content_cut;
    }
    if (texto.contains('planta')) {
      return Icons.local_florist;
    }
    if (texto.contains('perfil') || texto.contains('conta')) {
      return Icons.person_outline;
    }

    return Icons.eco;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de cuidados 🌿',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: salvando ? null : adicionarCuidado,
        backgroundColor: const Color(0xFFD4758D),
        child: salvando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: usuario == null
          ? const Center(
              child: Text('Entre na sua conta para ver o histórico.'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuario.uid)
                  .collection('historico')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o histórico.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final registros = snapshot.data?.docs ?? [];

                if (registros.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum cuidado registrado ainda 🌱\n'
                        'Toque no botão + para adicionar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final dados =
                        registros[index].data() as Map<String, dynamic>;

                    final acao = dados['acao']?.toString() ?? 'Cuidado';
                    final detalhes = dados['detalhes']?.toString() ?? '';
                    final data = formatarData(dados['data']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF8DDE5),
                          child: Icon(
                            iconePara(acao),
                            color: const Color(0xFFD4758D),
                          ),
                        ),
                        title: Text(
                          acao,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$detalhes\n$data'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
