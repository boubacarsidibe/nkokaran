import 'dart:math';

/// ------------------------------------------------------------------
/// Contenu — alphabet N'Ko (Unicode bloc U+07C0–U+07FF, vérifié)
/// ------------------------------------------------------------------

class NkoLetter {
  final String char;
  final String name;
  final String sound;
  const NkoLetter({required this.char, required this.name, required this.sound});
}

const vowels = [
  NkoLetter(char: "ߊ", name: "A", sound: "a"),
  NkoLetter(char: "ߋ", name: "É", sound: "é (fermé)"),
  NkoLetter(char: "ߌ", name: "I", sound: "i"),
  NkoLetter(char: "ߍ", name: "È", sound: "è (ouvert)"),
  NkoLetter(char: "ߎ", name: "OU", sound: "ou"),
  NkoLetter(char: "ߏ", name: "O", sound: "o"),
  NkoLetter(char: "ߐ", name: "Ô", sound: "ô (ouvert)"),
];

const consA = [
  NkoLetter(char: "ߓ", name: "BA", sound: "ba"),
  NkoLetter(char: "ߔ", name: "PA", sound: "pa"),
  NkoLetter(char: "ߕ", name: "TA", sound: "ta"),
  NkoLetter(char: "ߘ", name: "DA", sound: "da"),
  NkoLetter(char: "ߞ", name: "KA", sound: "ka"),
];

const consB = [
  NkoLetter(char: "ߖ", name: "DJA", sound: "dja"),
  NkoLetter(char: "ߗ", name: "TCHA", sound: "tcha"),
  NkoLetter(char: "ߛ", name: "SA", sound: "sa"),
  NkoLetter(char: "ߝ", name: "FA", sound: "fa"),
  NkoLetter(char: "ߤ", name: "HA", sound: "ha"),
];

const consC = [
  NkoLetter(char: "ߙ", name: "RA", sound: "ra"),
  NkoLetter(char: "ߚ", name: "RRA", sound: "rra (roulé)"),
  NkoLetter(char: "ߟ", name: "LA", sound: "la"),
  NkoLetter(char: "ߡ", name: "MA", sound: "ma"),
  NkoLetter(char: "ߣ", name: "NA", sound: "na"),
];

const consD = [
  NkoLetter(char: "ߜ", name: "GBA", sound: "gba"),
  NkoLetter(char: "ߢ", name: "NYA", sound: "nya"),
  NkoLetter(char: "ߥ", name: "WA", sound: "wa"),
  NkoLetter(char: "ߦ", name: "YA", sound: "ya"),
  NkoLetter(char: "ߒ", name: "N", sound: "n (nasale)"),
];

const digits = [
  NkoLetter(char: "߀", name: "0", sound: "zéro"),
  NkoLetter(char: "߁", name: "1", sound: "un"),
  NkoLetter(char: "߂", name: "2", sound: "deux"),
  NkoLetter(char: "߃", name: "3", sound: "trois"),
  NkoLetter(char: "߄", name: "4", sound: "quatre"),
  NkoLetter(char: "߅", name: "5", sound: "cinq"),
  NkoLetter(char: "߆", name: "6", sound: "six"),
  NkoLetter(char: "߇", name: "7", sound: "sept"),
  NkoLetter(char: "߈", name: "8", sound: "huit"),
  NkoLetter(char: "߉", name: "9", sound: "neuf"),
];

final allLetters = [...vowels, ...consA, ...consB, ...consC, ...consD];

class NkoUnit {
  final String id;
  final String title;
  final String subtitle;
  final List<NkoLetter>? letters;
  final List<NkoLetter>? pool;
  const NkoUnit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.letters,
    required this.pool,
  });
}

final units = <NkoUnit>[
  NkoUnit(id: "u1", title: "Les voyelles", subtitle: "7 sons de base", letters: vowels, pool: vowels),
  NkoUnit(id: "u2", title: "Consonnes I", subtitle: "ba · pa · ta · da · ka", letters: consA, pool: allLetters),
  NkoUnit(id: "u3", title: "Consonnes II", subtitle: "dja · tcha · sa · fa · ha", letters: consB, pool: allLetters),
  NkoUnit(id: "u4", title: "Consonnes III", subtitle: "ra · rra · la · ma · na", letters: consC, pool: allLetters),
  NkoUnit(id: "u5", title: "Consonnes IV", subtitle: "gba · nya · wa · ya · n", letters: consD, pool: allLetters),
  NkoUnit(id: "u6", title: "Les chiffres", subtitle: "de 0 à 9", letters: digits, pool: digits),
  const NkoUnit(id: "u7", title: "Ton premier mot", subtitle: "ߒߞߏ — le nom de l'écriture", letters: null, pool: null),
];

/// ------------------------------------------------------------------
/// Exercises
/// ------------------------------------------------------------------

enum ExerciseType { intro, wordIntro, quiz, match, wordBank }

enum QuizDirection { charToSound, soundToChar, text }

class Exercise {
  final ExerciseType type;
  final NkoLetter? letter;
  final QuizDirection? direction;
  final String? question;
  final String? displayChar;
  final String? correctLabel;
  final List<dynamic>? options; // List<NkoLetter> or List<String>
  final List<NkoLetter>? matchLetters; // for ExerciseType.match
  final List<String>? wordAnswer; // for ExerciseType.wordBank — correct tile order
  final List<String>? wordTiles; // for ExerciseType.wordBank — shuffled tile pool

  Exercise.intro(NkoLetter l)
      : type = ExerciseType.intro,
        letter = l,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null;

  Exercise.wordIntro()
      : type = ExerciseType.wordIntro,
        letter = null,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null;

  Exercise.quizLetter({
    required QuizDirection dir,
    required NkoLetter l,
    required List<NkoLetter> opts,
  })  : type = ExerciseType.quiz,
        letter = l,
        direction = dir,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = opts,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null;

  Exercise.quizText({
    required String question,
    String? displayChar,
    required String correctLabel,
    required List<String> options,
  })  : type = ExerciseType.quiz,
        letter = null,
        direction = QuizDirection.text,
        question = question,
        displayChar = displayChar,
        correctLabel = correctLabel,
        options = options,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null;

  Exercise.match(List<NkoLetter> letters)
      : type = ExerciseType.match,
        letter = null,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = letters,
        wordAnswer = null,
        wordTiles = null;

  Exercise.wordBank({
    required String question,
    required List<String> answer,
    required List<String> tiles,
  })  : type = ExerciseType.wordBank,
        letter = null,
        direction = null,
        question = question,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = answer,
        wordTiles = tiles;
}

final _rng = Random();

List<T> shuffle<T>(List<T> input) {
  final a = List<T>.from(input);
  for (var i = a.length - 1; i > 0; i--) {
    final j = _rng.nextInt(i + 1);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

List<NkoLetter> buildOptions(NkoLetter correct, List<NkoLetter> pool) {
  final others = shuffle(pool.where((x) => x.char != correct.char).toList()).take(3).toList();
  return shuffle([correct, ...others]);
}

List<Exercise> buildExercises(NkoUnit unit) {
  if (unit.id == "u7") {
    return [
      Exercise.wordIntro(),
      Exercise.wordBank(
        question: "Reconstitue ߒߞߏ en touchant les lettres dans le bon ordre",
        answer: const ["ߒ", "ߞ", "ߏ"],
        tiles: shuffle(const ["ߒ", "ߞ", "ߏ"]),
      ),
      Exercise.quizText(
        question: "Que signifie ce mot ?",
        displayChar: "ߒߞߏ",
        correctLabel: '"Je dis" — le nom de l\'écriture',
        options: shuffle([
          '"Je dis" — le nom de l\'écriture',
          '"Bonjour" — une salutation',
          '"Merci" — une politesse',
          '"École" — un lieu d\'étude',
        ]),
      ),
      Exercise.quizText(
        question: "Dans ߒߞߏ, quelle lettre est écrite EN PREMIER (à droite) ?",
        correctLabel: "ߒ (N)",
        options: shuffle(["ߒ (N)", "ߞ (K)", "ߏ (O)", "ߊ (A)"]),
      ),
      Exercise.quizText(
        question: "Le N'Ko se lit et s'écrit dans quel sens ?",
        correctLabel: "De droite à gauche",
        options: shuffle(["De droite à gauche", "De gauche à droite", "De haut en bas", "Aucun sens fixe"]),
      ),
    ];
  }

  final letters = unit.letters!;
  final pool = unit.pool!;
  final intros = letters.map((l) => Exercise.intro(l)).toList();
  final quizzes = <Exercise>[];
  for (var i = 0; i < letters.length; i++) {
    final l = letters[i];
    final dir = i % 2 == 0 ? QuizDirection.charToSound : QuizDirection.soundToChar;
    quizzes.add(Exercise.quizLetter(dir: dir, l: l, opts: buildOptions(l, pool)));
  }
  final matchStep = Exercise.match(shuffle(letters).take(6).toList());
  final shuffledQuizzes = shuffle(quizzes);
  // Mirrors Duolingo's lesson shape: teach each item, a matching-pairs
  // checkpoint, then mixed recall questions.
  return [...intros, matchStep, ...shuffledQuizzes];
}

/// Builds a fresh, endless stream of review exercises for the Practice hub —
/// same question types as a normal lesson, just not tied to unit completion.
List<Exercise> buildPracticeExercises(List<NkoLetter> letters, List<NkoLetter> pool, {int count = 8}) {
  final quizzes = <Exercise>[];
  for (var i = 0; i < count; i++) {
    final l = letters[_rng.nextInt(letters.length)];
    final dir = _rng.nextBool() ? QuizDirection.charToSound : QuizDirection.soundToChar;
    quizzes.add(Exercise.quizLetter(dir: dir, l: l, opts: buildOptions(l, pool)));
  }
  return quizzes;
}
