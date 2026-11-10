import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icone;
  final String? Function(String?)? validador;

  Editor(
    this.controller,
    this.label,
    this.hint,
    this.icone, {
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validador,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          icon: icone != null ? Icon(icone) : null,
        ),
      ),
    );
  }
}