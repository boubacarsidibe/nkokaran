import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class PrimaryButtonWide extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PrimaryButtonWide({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const SecondaryButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.ink),
      label: Text(label, style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
