import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Full-screen gate shown instead of the app while the signed-in user's
/// e-mail is unverified — verification is mandatory before any content is
/// reachable. Offers resend/check actions and a way to sign out (e.g. to
/// fix a typo'd address by creating a new account).
class EmailVerificationGateScreen extends StatefulWidget {
  final VoidCallback onVerified;
  const EmailVerificationGateScreen({super.key, required this.onVerified});

  @override
  State<EmailVerificationGateScreen> createState() => _EmailVerificationGateScreenState();
}

class _EmailVerificationGateScreenState extends State<EmailVerificationGateScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await AuthService.instance.sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = "E-mail envoyé — vérifie ta boîte de réception (et tes spams).";
    });
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final verified = await AuthService.instance.refreshEmailVerified();
    if (!mounted) return;
    if (verified) {
      widget.onVerified();
      return;
    }
    setState(() {
      _busy = false;
      _message = "Pas encore confirmé — clique le lien reçu par e-mail.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 40, color: AppColors.clay),
                const SizedBox(height: 12),
                Text("Confirme ton e-mail", style: AppText.fraunces(fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  "Un lien de confirmation a été envoyé à $email.\nClique-le puis reviens ici.",
                  textAlign: TextAlign.center,
                  style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, textAlign: TextAlign.center, style: AppText.inter(fontSize: 12, color: AppColors.indigo)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _check,
                  child: const Text("J'ai vérifié"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: const Text("Renvoyer l'e-mail"),
                ),
                TextButton(
                  onPressed: _busy ? null : () => AuthService.instance.signOut(),
                  child: const Text("Se déconnecter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

