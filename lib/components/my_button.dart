import 'package:flutter/material.dart';

class MyButton extends StatefulWidget {
  final Function()? onPressed;
  final formKey;
  final String text;

  const MyButton({
    super.key,
    required this.onPressed,
    required this.formKey,
    required this.text,
  });

  @override
  State<MyButton> createState() {
    return MyButtonState();
  }
}

class MyButtonState extends State<MyButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        height: 55,
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: () {
            if (widget.formKey.currentState!.validate()) {
              widget.onPressed!();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(18),
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
