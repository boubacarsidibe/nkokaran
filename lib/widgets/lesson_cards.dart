import 'dart:math';
import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../theme/app_theme.dart';
import 'option_grid.dart';

class IntroCard extends StatelessWidget {
  final NkoLetter letter;
  const IntroCard({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      children: [
        Text("NOUVELLE LETTRE",
            style: AppText.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.clay, letterSpacing: 1.5)),
        const SizedBox(height: 18),
        Text(letter.char, style: AppText.nko(fontSize: 96), textDirection: TextDirection.rtl),
        const SizedBox(height: 14),
        Text(letter.name, style: AppText.fraunces(fontSize: 22)),
        const SizedBox(height: 8),
        Text('se prononce « ${letter.sound} »',
            textAlign: TextAlign.center,
            style: AppText.inter(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.7))),
      ],
    );
  }
}

class WordIntroCard extends StatelessWidget {
  const WordIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      children: [
        Text("TON PREMIER MOT",
            style: AppText.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.clay, letterSpacing: 1.5)),
        const SizedBox(height: 18),
        Text("ߒߞߏ", style: AppText.nko(fontSize: 64), textDirection: TextDirection.rtl),
        const SizedBox(height: 14),
        Text("N'KO", style: AppText.fraunces(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          "composé de ߒ (n) + ߞ (k) + ߏ (o) — cela signifie « je dis » dans les langues manding, "
          "et c'est aussi le nom de cette écriture.",
          textAlign: TextAlign.center,
          style: AppText.inter(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w400)
              .copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final List<Widget> children;
  const _CardShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: children),
    );
  }
}

class QuizCard extends StatelessWidget {
  final Exercise exercise;
  final dynamic selected;
  final bool checked;
  final void Function(dynamic) onSelect;

  const QuizCard({
    super.key,
    required this.exercise,
    required this.selected,
    required this.checked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (exercise.direction == QuizDirection.charToSound) {
      final letter = exercise.letter!;
      final options = exercise.options!.cast<NkoLetter>();
      return _QuizShell(
        prompt: "Quel est le son de cette lettre ?",
        child: Column(
          children: [
            Text(letter.char, style: AppText.nko(fontSize: 76), textDirection: TextDirection.rtl),
            const SizedBox(height: 26),
            OptionGrid<NkoLetter>(
              options: options,
              renderLabel: (o) => o.sound,
              getKey: (o) => o.char,
              selected: selected as NkoLetter?,
              checked: checked,
              correctKey: letter.char,
              onSelect: onSelect,
            ),
          ],
        ),
      );
    }

    if (exercise.direction == QuizDirection.soundToChar) {
      final letter = exercise.letter!;
      final options = exercise.options!.cast<NkoLetter>();
      return _QuizShell(
        prompt: "Quelle lettre fait le son « ${letter.sound} » ?",
        child: OptionGrid<NkoLetter>(
          options: options,
          renderLabel: (o) => o.char,
          nko: true,
          getKey: (o) => o.char,
          selected: selected as NkoLetter?,
          checked: checked,
          correctKey: letter.char,
          onSelect: onSelect,
        ),
      );
    }

    // text direction
    final options = exercise.options!.cast<String>();
    return _QuizShell(
      prompt: exercise.question!,
      child: Column(
        children: [
          if (exercise.displayChar != null) ...[
            Text(exercise.displayChar!, style: AppText.nko(fontSize: 76), textDirection: TextDirection.rtl),
            const SizedBox(height: 26),
          ],
          OptionGrid<String>(
            options: options,
            renderLabel: (o) => o,
            getKey: (o) => o,
            selected: selected as String?,
            checked: checked,
            correctKey: exercise.correctLabel!,
            onSelect: onSelect,
            stacked: true,
          ),
        ],
      ),
    );
  }
}

class _QuizShell extends StatelessWidget {
  final String prompt;
  final Widget child;
  const _QuizShell({required this.prompt, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prompt,
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

/// Duolingo-style "match the pairs" checkpoint: tap a letter, then its sound.
/// Correct pairs lock in green; mismatches flash red and reset. Solving all
/// pairs auto-advances the lesson — there is no manual "Vérifier" step.
class MatchCard extends StatefulWidget {
  final List<NkoLetter> letters;
  final VoidCallback onSolved;

  const MatchCard({super.key, required this.letters, required this.onSolved});

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late List<NkoLetter> _left;
  late List<NkoLetter> _right;
  final Set<String> _matched = {};
  int? _selectedLeft;
  int? _selectedRight;
  Set<int>? _wrongLeft;
  Set<int>? _wrongRight;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _left = List.of(widget.letters)..shuffle(Random());
    _right = List.of(widget.letters)..shuffle(Random());
  }

  void _tapLeft(int i) {
    if (_matched.contains(_left[i].char) || _wrongLeft != null) return;
    setState(() => _selectedLeft = _selectedLeft == i ? null : i);
    _tryMatch();
  }

  void _tapRight(int i) {
    if (_matched.contains(_right[i].char) || _wrongRight != null) return;
    setState(() => _selectedRight = _selectedRight == i ? null : i);
    _tryMatch();
  }

  void _tryMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;
    final l = _left[_selectedLeft!];
    final r = _right[_selectedRight!];
    if (l.char == r.char) {
      setState(() {
        _matched.add(l.char);
        _selectedLeft = null;
        _selectedRight = null;
      });
      if (_matched.length == widget.letters.length && !_solved) {
        _solved = true;
        Future.delayed(const Duration(milliseconds: 250), widget.onSolved);
      }
    } else {
      final wl = _selectedLeft!;
      final wr = _selectedRight!;
      setState(() {
        _wrongLeft = {wl};
        _wrongRight = {wr};
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _wrongLeft = null;
          _wrongRight = null;
          _selectedLeft = null;
          _selectedRight = null;
        });
      });
    }
  }

  Widget _tile({
    required String label,
    required bool nko,
    required bool matched,
    required bool selected,
    required bool wrong,
    required VoidCallback onTap,
  }) {
    Color bg = AppColors.card;
    Color border = AppColors.line;
    if (matched) {
      bg = AppColors.correctBg;
      border = AppColors.green;
    } else if (wrong) {
      bg = AppColors.wrongBg;
      border = AppColors.red;
    } else if (selected) {
      bg = AppColors.selectedBg;
      border = AppColors.gold;
    }
    return GestureDetector(
      onTap: matched ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: matched ? 0.35 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textDirection: nko ? TextDirection.rtl : TextDirection.ltr,
            style: nko
                ? AppText.nko(fontSize: 24)
                : AppText.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Associe chaque lettre à son son",
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _left.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _tile(
                        label: _left[i].char,
                        nko: true,
                        matched: _matched.contains(_left[i].char),
                        selected: _selectedLeft == i,
                        wrong: _wrongLeft?.contains(i) ?? false,
                        onTap: () => _tapLeft(i),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _right.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _tile(
                        label: _right[i].sound,
                        nko: false,
                        matched: _matched.contains(_right[i].char),
                        selected: _selectedRight == i,
                        wrong: _wrongRight?.contains(i) ?? false,
                        onTap: () => _tapRight(i),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Duolingo-style tile-tap exercise: tap letters from the bank, in order,
/// to assemble the target word. Reports the assembled sequence upward
/// through [onChanged] so the shared "Vérifier" footer button can drive it.
class WordBankCard extends StatefulWidget {
  final String question;
  final List<String> tiles;
  final List<String> answer;
  final void Function(List<String>? assembled) onChanged;

  const WordBankCard({
    super.key,
    required this.question,
    required this.tiles,
    required this.answer,
    required this.onChanged,
  });

  @override
  State<WordBankCard> createState() => _WordBankCardState();
}

class _WordBankCardState extends State<WordBankCard> {
  late List<String> _bank;
  final List<String> _picked = [];

  @override
  void initState() {
    super.initState();
    _bank = List.of(widget.tiles);
  }

  void _pick(int i) {
    setState(() {
      _picked.add(_bank.removeAt(i));
    });
    _report();
  }

  void _unpick(int i) {
    setState(() {
      _bank.add(_picked.removeAt(i));
    });
    _report();
  }

  void _report() {
    widget.onChanged(_picked.length == widget.answer.length ? List.of(_picked) : null);
  }

  Widget _chip(String label, VoidCallback onTap, {bool ghost = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : AppColors.card,
          border: Border.all(color: AppColors.line, width: ghost ? 1 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: AppText.nko(fontSize: 26),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.question,
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                for (var i = 0; i < _picked.length; i++) _chip(_picked[i], () => _unpick(i)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _bank.length; i++) _chip(_bank[i], () => _pick(i)),
            ],
          ),
        ],
      ),
    );
  }
}
