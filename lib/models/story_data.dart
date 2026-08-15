/// Narrative episodes — a "season" track running in parallel to the
/// letters/units path. Visual-novel-style: characters speak line by line
/// in N'Ko with French subtitles, occasionally branching on a player
/// choice, then a short comprehension quiz closes the episode.
library;

enum Dialect { maninka, bambara, dioula }

extension DialectLabel on Dialect {
  String get label => switch (this) {
        Dialect.maninka => "maninka",
        Dialect.bambara => "bambara",
        Dialect.dioula => "dioula",
      };
}

class StoryCharacter {
  final String id;
  final String name;
  final Dialect dialect;
  const StoryCharacter({required this.id, required this.name, required this.dialect});
}

/// One line of dialogue. [nextId] chains to the next line by default;
/// branching lines instead carry [choices], each pointing at a different
/// [DialogueChoice.nextId].
class DialogueLine {
  final String id;
  final StoryCharacter speaker;
  final String nko;
  final String french;
  final String? nextId;
  final List<DialogueChoice>? choices;

  const DialogueLine({
    required this.id,
    required this.speaker,
    required this.nko,
    required this.french,
    this.nextId,
    this.choices,
  });
}

class DialogueChoice {
  final String label;
  final String nextId;
  const DialogueChoice({required this.label, required this.nextId});
}

class ComprehensionQuestion {
  final String question;
  final String correctLabel;
  final List<String> options;
  const ComprehensionQuestion({required this.question, required this.correctLabel, required this.options});
}

class StoryEpisode {
  final String id;
  final String title;
  final String subtitle;
  final List<StoryCharacter> characters;
  final String startId;
  final Map<String, DialogueLine> lines;
  final List<ComprehensionQuestion> quiz;

  const StoryEpisode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.characters,
    required this.startId,
    required this.lines,
    required this.quiz,
  });
}

/// ------------------------------------------------------------------
/// Episode 1 — "Sur le marché de Kankan"
/// Sekou (maninka) rencontre Aïcha (bambara) sur le marché ; il apprend à
/// saluer et à demander un prix. Deux embranchements changent la fin.
/// ------------------------------------------------------------------

const _sekou = StoryCharacter(id: "sekou", name: "Sekou", dialect: Dialect.maninka);
const _aicha = StoryCharacter(id: "aicha", name: "Aïcha", dialect: Dialect.bambara);

final episode1 = StoryEpisode(
  id: "ep1",
  title: "Sur le marché de Kankan",
  subtitle: "Sekou apprend à saluer et à marchander",
  characters: const [_sekou, _aicha],
  startId: "l1",
  quiz: const [
    ComprehensionQuestion(
      question: "Que veut acheter Sekou sur le marché ?",
      correctLabel: "Des mangues",
      options: ["Des mangues", "Du riz", "Un tissu", "De l'eau"],
    ),
    ComprehensionQuestion(
      question: "D'où vient Aïcha ?",
      correctLabel: "Elle parle bambara",
      options: ["Elle parle bambara", "Elle parle dioula", "Elle parle français", "Elle ne parle pas"],
    ),
    ComprehensionQuestion(
      question: "Comment dit-on « merci » dans le dialogue ?",
      correctLabel: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ (i ni sɛ̀nɛ / merci)",
      options: [
        "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ (i ni sɛ̀nɛ / merci)",
        "ߌ ߣߌ߫ ߛߏ߬ (bonsoir)",
        "ߊ߲ ߠߊ߫ (à nous)",
        "ߒߤߏ߲߬ (non)",
      ],
    ),
  ],
  lines: {
    "l1": const DialogueLine(
      id: "l1",
      speaker: _sekou,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬!",
      french: "Bonjour !",
      nextId: "l2",
    ),
    "l2": const DialogueLine(
      id: "l2",
      speaker: _aicha,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬! ߌ ߦߋ߫ ߘߌ߬ ߟߊ߫؟",
      french: "Bonjour ! Comment vas-tu ?",
      nextId: "l3",
    ),
    "l3": const DialogueLine(
      id: "l3",
      speaker: _sekou,
      nko: "ߒ ߦߋ߫ ߤߋߙߋ߲ ߠߋ߬ ߘߌ߫. ߊ߬ ߣߌ߫ ߌߟߋ؟",
      french: "Je vais bien. Et toi ?",
      nextId: "l4",
    ),
    "l4": const DialogueLine(
      id: "l4",
      speaker: _aicha,
      nko: "ߒ ߝߣߊ߫ ߦߋ߫ ߤߋߙߋ߲ ߠߋ߬ ߘߌ߫. ߌ ߦߋ߫ ߡߎ߲߬ ߠߊ߫ ߣߌ߲߬؟",
      french: "Moi aussi, ça va bien. Qu'est-ce que tu cherches ?",
      nextId: "l5",
    ),
    "l5": const DialogueLine(
      id: "l5",
      speaker: _sekou,
      nko: "ߒ ߧߋ߫ ߡߊ߲߬ߜ ߠߎ߬ ߝߍ߬.",
      french: "Je cherche des mangues.",
      nextId: "choice1",
    ),
    "choice1": const DialogueLine(
      id: "choice1",
      speaker: _aicha,
      nko: "ߒ ߦߴߏ߬ ߟߎ߬ ߘߊ߫ ߦߋ߲߬. ߌ ߦߋ߫ ߖߋ߬ߟߌ ߛߌ߬ߡߛߊ߬؟",
      french: "J'en ai ici. Tu en veux combien ?",
      choices: [
        DialogueChoice(label: "« Quelques-unes seulement »", nextId: "l6a"),
        DialogueChoice(label: "« Beaucoup, pour toute la famille »", nextId: "l6b"),
      ],
    ),
    "l6a": const DialogueLine(
      id: "l6a",
      speaker: _sekou,
      nko: "ߘߋ߲ߘߋ߲ ߟߋ߬ ߘߐ߫, ߒ ߞߊ߬ ߒ ߖߘߍ߬ ߦߴߏ߬ ߦߋ߫.",
      french: "Juste quelques-unes, c'est pour moi.",
      nextId: "l7",
    ),
    "l6b": const DialogueLine(
      id: "l6b",
      speaker: _sekou,
      nko: "ߛߌߦߊ ߟߋ߬, ߒ ߓߊߘߋ߲ ߠߎ߬ ߦߋ߫ ߣߌ߲߬.",
      french: "Beaucoup, c'est pour toute ma famille.",
      nextId: "l7",
    ),
    "l7": const DialogueLine(
      id: "l7",
      speaker: _aicha,
      nko: "ߊ߬ ߘߌ߫ ߣߊ߬ ߒ ߝߍ߬.",
      french: "D'accord, viens avec moi.",
      nextId: "l8",
    ),
    "l8": const DialogueLine(
      id: "l8",
      speaker: _sekou,
      nko: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲!",
      french: "Merci !",
      nextId: null,
    ),
  },
);

/// ------------------------------------------------------------------
/// Episode 2 — "Combien de mangues ?"
/// Sekou revient au marché acheter ses mangues ; Moussa (dioula), le frère
/// d'Aïcha, l'aide à compter en N'Ko. N'Ko content here reuses phrases
/// already verified in episode 1 (greetings, "merci", "des mangues", "ici")
/// plus the digit glyphs from the app's own alphabet data, rather than
/// introducing new unverified N'Ko sentences.
/// ------------------------------------------------------------------

const _moussa = StoryCharacter(id: "moussa", name: "Moussa", dialect: Dialect.dioula);

final episode2 = StoryEpisode(
  id: "ep2",
  title: "Combien de mangues ?",
  subtitle: "Sekou revient marchander, et compte en N'Ko avec Moussa",
  characters: const [_sekou, _aicha, _moussa],
  startId: "l1",
  quiz: const [
    ComprehensionQuestion(
      question: "Qui est Moussa ?",
      correctLabel: "Le frère d'Aïcha",
      options: ["Le frère d'Aïcha", "Le père de Sekou", "Un client", "Le vendeur de riz"],
    ),
    ComprehensionQuestion(
      question: "Quel chiffre correspond à ߃ ?",
      correctLabel: "Trois",
      options: ["Trois", "Cinq", "Sept", "Un"],
    ),
    ComprehensionQuestion(
      question: "Que dit Sekou pour remercier Moussa de l'avoir aidé à compter ?",
      correctLabel: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ (merci)",
      options: [
        "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ (merci)",
        "ߌ ߣߌ߫ ߛߏ߬ (bonsoir)",
        "ߊ߲ ߠߊ߫ (à nous)",
        "ߒߤߏ߲߬ (non)",
      ],
    ),
  ],
  lines: {
    "l1": const DialogueLine(
      id: "l1",
      speaker: _sekou,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬!",
      french: "Bonjour !",
      nextId: "l2",
    ),
    "l2": const DialogueLine(
      id: "l2",
      speaker: _aicha,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬! ߌ ߦߋ߫ ߘߌ߬ ߟߊ߫؟",
      french: "Bonjour ! Comment vas-tu ?",
      nextId: "l3",
    ),
    "l3": const DialogueLine(
      id: "l3",
      speaker: _sekou,
      nko: "ߒ ߦߋ߫ ߤߋߙߋ߲ ߠߋ߬ ߘߌ߫.",
      french: "Je vais bien.",
      nextId: "l4",
    ),
    "l4": const DialogueLine(
      id: "l4",
      speaker: _aicha,
      nko: "ߡߊ߲߬ߜ ߟߎ߬ ߦߋ߲߬!",
      french: "Les mangues sont là !",
      nextId: "l5",
    ),
    "l5": const DialogueLine(
      id: "l5",
      speaker: _sekou,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬!",
      french: "Bonjour ! (à Moussa, qui vient d'arriver)",
      nextId: "l6",
    ),
    "l6": const DialogueLine(
      id: "l6",
      speaker: _moussa,
      nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬!",
      french: "Bonjour ! Je m'appelle Moussa, le frère d'Aïcha.",
      nextId: "choice1",
    ),
    "choice1": const DialogueLine(
      id: "choice1",
      speaker: _aicha,
      nko: "ߌ ߦߋ߫ ߖߋ߬ߟߌ ߛߌ߬ߡߛߊ߬؟",
      french: "Tu en veux combien ?",
      choices: [
        DialogueChoice(label: "« Trois (߃) »", nextId: "l7a"),
        DialogueChoice(label: "« Cinq (߅) »", nextId: "l7b"),
      ],
    ),
    "l7a": const DialogueLine(
      id: "l7a",
      speaker: _sekou,
      nko: "߃.",
      french: "Trois.",
      nextId: "l8",
    ),
    "l7b": const DialogueLine(
      id: "l7b",
      speaker: _sekou,
      nko: "߅.",
      french: "Cinq.",
      nextId: "l8",
    ),
    "l8": const DialogueLine(
      id: "l8",
      speaker: _moussa,
      nko: "߁, ߂, ߃, ߄, ߅...",
      french: "Un, deux, trois, quatre, cinq... (il compte les mangues avec lui)",
      nextId: "l9",
    ),
    "l9": const DialogueLine(
      id: "l9",
      speaker: _sekou,
      nko: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲!",
      french: "Merci !",
      nextId: "l10",
    ),
    "l10": const DialogueLine(
      id: "l10",
      speaker: _moussa,
      nko: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲!",
      french: "Merci ! (il salue Sekou avant de repartir)",
      nextId: null,
    ),
  },
);

final storyEpisodes = <StoryEpisode>[episode1, episode2];
