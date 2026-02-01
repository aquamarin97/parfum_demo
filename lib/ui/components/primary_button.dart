// primary_button.dart
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 120.0, // Varsayılan değer 100 olarak belirlendi
    this.enabled = true,
    this.paddingHorizontal = 150,
    this.paddingvertical = 30,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double fontSize;
  final double paddingHorizontal;
  final double paddingvertical;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingvertical,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        // Değişken kullanıldığı için style kısmında const kullanılmaz
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}
