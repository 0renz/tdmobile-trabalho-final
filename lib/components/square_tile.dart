import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  final double height;
  final Function()? onTap;

  const SquareTile({
    super.key,
    required this.imagePath,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(10),
        backgroundColor: Colors.grey[300],
        side: BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: SvgPicture.asset(
        imagePath,
        height: height,
      ),
    );
  }
}
