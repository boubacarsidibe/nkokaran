import 'package:flutter/material.dart';

class BadgeDef {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  const BadgeDef({required this.id, required this.label, required this.description, required this.icon});
}

const badgeCatalog = [
  BadgeDef(
    id: "first_lesson",
    label: "Premier pas",
    description: "Termine ta première leçon",
    icon: Icons.flag,
  ),
  BadgeDef(
    id: "perfectionist",
    label: "Sans faute",
    description: "Termine une leçon sans te tromper",
    icon: Icons.star,
  ),
  BadgeDef(
    id: "week_streak",
    label: "Une semaine",
    description: "Atteins une série de 7 jours",
    icon: Icons.local_fire_department,
  ),
  BadgeDef(
    id: "alphabet_complete",
    label: "Alphabet complet",
    description: "Maîtrise toutes les lettres et les chiffres",
    icon: Icons.abc,
  ),
  BadgeDef(
    id: "nko_graduate",
    label: "Diplômé N'Ko",
    description: "Termine les 7 leçons du parcours",
    icon: Icons.school,
  ),
];
