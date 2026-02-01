import 'package:flutter/material.dart';

class PrimaryOutlinedButton extends StatelessWidget {
  const PrimaryOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 50,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 30),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 3,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
