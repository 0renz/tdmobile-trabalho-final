import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final icon;
  final bool obscureText;
  final bool capitalization;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.obscureText,
    required this.capitalization,
  });

  @override
  State<MyTextField> createState() {
    return MyTextFieldState();
  }
}

class MyTextFieldState extends State<MyTextField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: TextFormField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Preenchimento obrigatório!';
            }
            return null;
          },
          onFieldSubmitted: (value) {
            setState(() {
              widget.controller.text = value;
            });
          },
          textCapitalization: widget.capitalization
              ? TextCapitalization.words
              : TextCapitalization.none,
          controller: widget.controller,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.grey.shade600),
              ),
              filled: true,
              fillColor: Colors.grey.shade300,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: Padding(
                padding: EdgeInsets.all(0.0),
                child: widget.icon,
              )),
        ),
      ),
    );
  }
}
