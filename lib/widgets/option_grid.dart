import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One selectable answer tile, styled per its correctness state once checked.
class OptionTile<T> extends StatelessWidget {
  final T option;
  final String label;
  final bool nko;
  final bool isSelected;
  final bool checked;
  final bool isCorrectOption;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.option,
    required this.label,
    required this.nko,
    required this.isSelected,
    required this.checked,
    required this.isCorrectOption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.card;
    Color border = AppColors.line;
    if (checked && isCorrectOption) {
      bg = AppColors.correctBg;
      border = AppColors.green;
    } else if (checked && isSelected && !isCorrectOption) {
      bg = AppColors.wrongBg;
      border = AppColors.red;
    } else if (!checked && isSelected) {
      bg = AppColors.selectedBg;
      border = AppColors.gold;
    }

    return GestureDetector(
      onTap: checked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          textDirection: nko ? TextDirection.rtl : TextDirection.ltr,
          style: nko
              ? AppText.nko(fontSize: 34, fontWeight: FontWeight.w600)
              : AppText.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Grid (2-col) or stacked (1-col) layout of [OptionTile]s.
class OptionGrid<T> extends StatelessWidget {
  final List<T> options;
  final String Function(T) renderLabel;
  final Object Function(T) getKey;
  final T? selected;
  final bool checked;
  final Object correctKey;
  final void Function(T) onSelect;
  final bool nko;
  final bool stacked;

  const OptionGrid({
    super.key,
    required this.options,
    required this.renderLabel,
    required this.getKey,
    required this.selected,
    required this.checked,
    required this.correctKey,
    required this.onSelect,
    this.nko = false,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = options.map((o) {
      final key = getKey(o);
      final isSelected = selected != null && getKey(selected as T) == key;
      final isCorrectOption = key == correctKey;
      return OptionTile<T>(
        option: o,
        label: renderLabel(o),
        nko: nko,
        isSelected: isSelected,
        checked: checked,
        isCorrectOption: isCorrectOption,
        onTap: () => onSelect(o),
      );
    }).toList();

    if (stacked) {
      return Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: tiles[i]),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: tiles,
    );
  }
}
