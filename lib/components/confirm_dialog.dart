import 'package:flutter/material.dart';

/// Janela de confirmação para ações destrutivas. Devolve true só se o
/// usuário confirmar; fechar a janela ou tocar em "Cancelar" devolve false.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmarTexto = 'Excluir',
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmarTexto),
          ),
        ],
      );
    },
  );
  return confirmado ?? false;
}
