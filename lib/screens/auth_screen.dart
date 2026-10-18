import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/cloth_border.dart';

/// Mandatory sign-in gate shown before any lesson content — see [AuthGate]
/// in main.dart. Toggles between login and account creation.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Renseigne un e-mail et un mot de passe.");
      return;
    }
    if (_isSignUp && name.isEmpty) {
      setState(() => _error = "Choisis un pseudo.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final error = _isSignUp
        ? await AuthService.instance.signUp(email: email, password: password, displayName: name)
        : await AuthService.instance.signIn(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = "Renseigne ton e-mail ci-dessus, puis appuie de nouveau sur ce lien.";
        _info = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final error = await AuthService.instance.sendPasswordReset(email: email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      _info = error == null ? "E-mail envoyé — vérifie ta boîte de réception (et tes spams)." : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClothBorder(),
                  const SizedBox(height: 24),
                  Text("N'Ko Kalan", textAlign: TextAlign.center, style: AppText.fraunces(fontSize: 30, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(
                    "Apprends à lire et écrire le ߒߞߏ",
                    textAlign: TextAlign.center,
                    style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isSignUp ? "Créer un compte" : "Connexion",
                    style: AppText.fraunces(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  if (_isSignUp) ...[
                    const _FieldLabel("Pseudo"),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration("Ton nom affiché dans la ligue"),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const _FieldLabel("E-mail"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _inputDecoration("toi@exemple.com"),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel("Mot de passe"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: _inputDecoration("6 caractères minimum"),
                  ),
                  if (!_isSignUp) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: Text(
                          "Mot de passe oublié ?",
                          style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppText.inter(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600)),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 12),
                    Text(_info!, style: AppText.inter(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
                      : PrimaryButton(
                          label: _isSignUp ? "Créer mon compte" : "Se connecter",
                          onPressed: _submit,
                        ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                                _info = null;
                              }),
                      child: Text(
                        _isSignUp ? "J'ai déjà un compte — me connecter" : "Pas de compte — en créer un",
                        style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.indigo),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink.withValues(alpha: 0.7)));
  }
}
