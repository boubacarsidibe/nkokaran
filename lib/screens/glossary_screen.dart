import 'package:flutter/material.dart';
import '../models/culture_data.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

/// Feature 24 — searchable glossary of every word/letter taught so far,
/// each with a "play" button. Audio via Djelia (voix bambara) — see [TtsService].
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final filtered = glossaryEntries.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.latin.toLowerCase().contains(q) || e.meaning.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text("Glossaire", style: AppText.fraunces(fontSize: 20)),
        foregroundColor: AppColors.ink,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: "Rechercher un mot…",
                      prefixIcon: const Icon(Icons.search, color: AppColors.ink),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _GlossaryRow(entry: filtered[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlossaryRow extends StatelessWidget {
  final GlossaryEntry entry;
  const _GlossaryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppColors.indigo),
            onPressed: () => speakOrNotify(context, entry.latin),
          ),
          const SizedBox(width: 4),
          Text(entry.nko, textDirection: TextDirection.rtl, style: AppText.nko(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.latin, style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(entry.meaning, style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
