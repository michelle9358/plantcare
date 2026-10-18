import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<void> registrarHistorico(String acao, {String detalhes = ''}) async {
  final usuario = FirebaseAuth.instance.currentUser;

  if (usuario == null) {
    return;
  }

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
    debugPrint('Erro ao registrar histórico: $e');
  }
}
