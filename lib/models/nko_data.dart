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
final allLettersAndDigits = [...allLetters, ...digits];

NkoLetter? letterByChar(String char) {
  for (final l in allLettersAndDigits) {
    if (l.char == char) return l;
  }
  return null;
}

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
  const NkoUnit(id: "u1", title: "Les voyelles", subtitle: "7 sons de base", letters: vowels, pool: vowels),
  NkoUnit(id: "u2", title: "Consonnes I", subtitle: "ba · pa · ta · da · ka", letters: consA, pool: allLetters),
  NkoUnit(id: "u3", title: "Consonnes II", subtitle: "dja · tcha · sa · fa · ha", letters: consB, pool: allLetters),
  NkoUnit(id: "u4", title: "Consonnes III", subtitle: "ra · rra · la · ma · na", letters: consC, pool: allLetters),
  NkoUnit(id: "u5", title: "Consonnes IV", subtitle: "gba · nya · wa · ya · n", letters: consD, pool: allLetters),
  const NkoUnit(id: "u6", title: "Les chiffres", subtitle: "de 0 à 9", letters: digits, pool: digits),
  const NkoUnit(id: "u7", title: "Ton premier mot", subtitle: "ߒߞߏ — le nom de l'écriture", letters: null, pool: null),
  const NkoUnit(id: "u8", title: "Salutations", subtitle: "Bonjour · merci · mangue", letters: null, pool: null),
  const NkoUnit(id: "u9", title: "Au marché", subtitle: "Le dialogue de Sekou et Aïcha", letters: null, pool: null),
];

/// A short phrase or word — used for vocabulary units (as opposed to the
/// single-letter [NkoLetter] units above). [phonetic] is a Latin-alphabet
/// approximation fed to TTS (see TtsService); left null when no verified
/// transliteration exists for the phrase, in which case the pronunciation
/// drill is simply skipped rather than guessing one.
class VocabWord {
  final String nko;
  final String? phonetic;
  final String meaning;
  const VocabWord({required this.nko, this.phonetic, required this.meaning});
}

/// Vocabulary for unit u8 — reuses exactly the greetings/words already
/// verified elsewhere in the app (the audio glossary and the story
/// episodes) rather than authoring new N'Ko text, for the same accuracy
/// reasons noted on [translationExercises].
const salutationsWords = <VocabWord>[
  VocabWord(nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", phonetic: "i ni sɔgɔma", meaning: "Bonjour"),
  VocabWord(nko: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲", phonetic: "i ni sɛnɛ", meaning: "Merci"),
  VocabWord(nko: "ߡߊ߲߬ߜ", phonetic: "mangɛ", meaning: "Mangue"),
];

/// Vocabulary for unit u9 — three clean, single-sentence dialogue lines
/// reused verbatim from episode1/episode2 in story_data.dart (skipping
/// lines that combine two sentences or carry a stage direction, same filter
/// [buildVocabQuestions] applies). No Latin phonetic was ever authored for
/// these full sentences, so [VocabWord.phonetic] is left null here rather
/// than inventing a transliteration.
const marketWords = <VocabWord>[
  VocabWord(nko: "ߒ ߧߋ߫ ߡߊ߲߬ߜ ߠߎ߬ ߝߍ߬.", meaning: "Je cherche des mangues."),
  VocabWord(nko: "ߡߊ߲߬ߜ ߟߎ߬ ߦߋ߲߬!", meaning: "Les mangues sont là !"),
  VocabWord(nko: "ߊ߬ ߘߌ߫ ߣߊ߬ ߒ ߝߍ߬.", meaning: "D'accord, viens avec moi."),
];

/// ------------------------------------------------------------------
/// Exercises
/// ------------------------------------------------------------------

enum ExerciseType { intro, wordIntro, quiz, match, wordBank, listening, pronunciation, handwriting, dictation }

enum QuizDirection { charToSound, soundToChar, text }

/// A short French explanation shown under a wrong answer — feature 21
/// ("pourquoi c'est faux"). Kept optional since intro/match steps don't
/// have a wrong-answer state to explain.
class Exercise {
  final ExerciseType type;
  final NkoLetter? letter;
  final QuizDirection? direction;
  final String? question;
  final String? displayChar;
  final String? correctLabel;
  final List<dynamic>? options; // List<NkoLetter> or List<String>
  final List<NkoLetter>? matchLetters; // for ExerciseType.match
  final List<String>? wordAnswer; // for ExerciseType.wordBank/dictation — correct tile order
  final List<String>? wordTiles; // for ExerciseType.wordBank/dictation — shuffled tile pool
  final String? explanation;
  final String? spokenText; // for ExerciseType.listening/pronunciation/dictation — TTS input
  final String? targetWord; // for ExerciseType.pronunciation — word shown to read aloud
  final String? targetPhonetic; // for ExerciseType.pronunciation — loose Latin-alphabet reference to match STT output against

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
        wordTiles = null,
        explanation = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

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
        wordTiles = null,
        explanation = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

  Exercise.quizLetter({
    required QuizDirection dir,
    required NkoLetter l,
    required List<NkoLetter> opts,
    this.explanation,
  })  : type = ExerciseType.quiz,
        letter = l,
        direction = dir,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = opts,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

  Exercise.quizText({
    required this.question,
    this.displayChar,
    required this.correctLabel,
    required List<String> this.options,
    this.explanation,
  })  : type = ExerciseType.quiz,
        letter = null,
        direction = QuizDirection.text,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

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
        wordTiles = null,
        explanation = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

  Exercise.wordBank({
    required this.question,
    required List<String> answer,
    required List<String> tiles,
  })  : type = ExerciseType.wordBank,
        letter = null,
        direction = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = answer,
        wordTiles = tiles,
        explanation = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

  /// Plays [spokenText] via TTS, then asks the learner to pick which letter
  /// they heard among [opts] — feature 16 (listening exercises).
  Exercise.listening({
    required NkoLetter l,
    required this.spokenText,
    required List<NkoLetter> opts,
  })  : type = ExerciseType.listening,
        letter = l,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = opts,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null,
        explanation = null,
        targetWord = null,
        targetPhonetic = null;

  /// Shows [targetWord] and records the learner reading it aloud, compared
  /// best-effort against [targetPhonetic] — feature 17 (pronunciation).
  Exercise.pronunciation({
    required this.targetWord,
    required this.targetPhonetic,
  })  : type = ExerciseType.pronunciation,
        letter = null,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null,
        explanation = null,
        spokenText = null;

  /// Free-hand tracing of [letter] on a canvas — feature 18 (handwriting).
  Exercise.handwriting(NkoLetter l)
      : type = ExerciseType.handwriting,
        letter = l,
        direction = null,
        question = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = null,
        wordTiles = null,
        explanation = null,
        spokenText = null,
        targetWord = null,
        targetPhonetic = null;

  /// Plays [spokenText] via TTS and asks the learner to reconstruct it from
  /// letter tiles — feature 20 (dictation).
  Exercise.dictation({
    required this.question,
    required this.spokenText,
    required List<String> answer,
    required List<String> tiles,
  })  : type = ExerciseType.dictation,
        letter = null,
        direction = null,
        displayChar = null,
        correctLabel = null,
        options = null,
        matchLetters = null,
        wordAnswer = answer,
        wordTiles = tiles,
        explanation = null,
        targetWord = null,
        targetPhonetic = null;
}

/// Bidirectional short-phrase translation drills (N'Ko→français and
/// français→N'Ko) — feature 19. Built only from vocabulary already
/// verified elsewhere in the app (greetings and "mangue" from the story
/// episodes/glossary, digit glyphs from [digits]) rather than inventing new
/// N'Ko sentences, for the same accuracy reasons noted on episode 2.
final translationExercises = <Exercise>[
  Exercise.quizText(
    question: "Comment dit-on « bonjour » en N'Ko ?",
    correctLabel: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬",
    options: shuffle(["ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲", "ߡߊ߲߬ߜ", "ߒߞߏ"]),
    explanation: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬ (i ni sɔgɔma) est la salutation utilisée par Sekou et Aïcha au marché.",
  ),
  Exercise.quizText(
    question: "Que veut dire « ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬ » ?",
    correctLabel: "Bonjour",
    options: shuffle(["Bonjour", "Merci", "Mangue", "Au revoir"]),
  ),
  Exercise.quizText(
    question: "Comment dit-on « merci » en N'Ko ?",
    correctLabel: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲",
    options: shuffle(["ߌ ߣߌ߫ ߖߊ߬ߣߍ߲", "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", "ߡߊ߲߬ߜ", "ߒߞߏ"]),
    explanation: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ (i ni sɛnɛ) est ce que dit Sekou pour remercier Aïcha et Moussa.",
  ),
  Exercise.quizText(
    question: "Que veut dire « ߌ ߣߌ߫ ߖߊ߬ߣߍ߲ » ?",
    correctLabel: "Merci",
    options: shuffle(["Merci", "Bonjour", "Mangue", "Combien ?"]),
  ),
  Exercise.quizText(
    question: "Comment dit-on « mangue » en N'Ko ?",
    correctLabel: "ߡߊ߲߬ߜ",
    options: shuffle(["ߡߊ߲߬ߜ", "ߒߞߏ", "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲"]),
    explanation: "ߡߊ߲߬ߜ (mangɛ) est ce que Sekou vient acheter au marché dans l'épisode 1.",
  ),
  Exercise.quizText(
    question: "Que veut dire « ߡߊ߲߬ߜ » ?",
    correctLabel: "Mangue",
    options: shuffle(["Mangue", "Bonjour", "Merci", "École"]),
  ),
  Exercise.quizText(
    question: "Comment écrit-on « trois » en chiffre N'Ko ?",
    correctLabel: "߃",
    options: shuffle(["߃", "߁", "߅", "߉"]),
  ),
  Exercise.quizText(
    question: "Quel nombre représente ce chiffre N'Ko : ߅ ?",
    correctLabel: "Cinq",
    options: shuffle(["Cinq", "Trois", "Sept", "Un"]),
  ),
  Exercise.quizText(
    question: "Comment écrit-on « sept » en chiffre N'Ko ?",
    correctLabel: "߇",
    options: shuffle(["߇", "߂", "߄", "߈"]),
  ),
  Exercise.quizText(
    question: "Comment dit-on « je dis » — le nom de l'écriture N'Ko — en N'Ko ?",
    correctLabel: "ߒߞߏ",
    options: shuffle(["ߒߞߏ", "ߡߊ߲߬ߜ", "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲"]),
    explanation: "ߒߞߏ (n-ko) veut dire « je dis » — c'est le nom donné à l'écriture par Solomana Kanté.",
  ),
];

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
  if (unit.id == "u9") {
    return buildVocabExercises(marketWords);
  }
  if (unit.id == "u8") {
    return buildVocabExercises(salutationsWords);
  }
  if (unit.id == "u7") {
    return [
      Exercise.wordIntro(),
      Exercise.wordBank(
        question: "Reconstitue ߒߞߏ en touchant les lettres dans le bon ordre",
        answer: const ["ߒ", "ߞ", "ߏ"],
        tiles: shuffle(const ["ߒ", "ߞ", "ߏ"]),
      ),
      Exercise.listening(
        l: const NkoLetter(char: "ߒߞߏ", name: "N'KO", sound: "n-ko"),
        spokenText: "n ko",
        opts: const [
          NkoLetter(char: "ߒߞߏ", name: "N'KO", sound: "n-ko"),
          NkoLetter(char: "ߊ", name: "A", sound: "a"),
          NkoLetter(char: "ߓ", name: "BA", sound: "ba"),
          NkoLetter(char: "ߛ", name: "SA", sound: "sa"),
        ],
      ),
      Exercise.pronunciation(targetWord: "ߒߞߏ", targetPhonetic: "n ko"),
      Exercise.dictation(
        question: "Écoute et reconstitue le mot que tu entends",
        spokenText: "n ko",
        answer: const ["ߒ", "ߞ", "ߏ"],
        tiles: shuffle(const ["ߒ", "ߞ", "ߏ", "ߊ", "ߛ"]),
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
        explanation: "ߒߞߏ (n-ko) veut dire « je dis » dans les langues manding — c'est aussi le nom donné à cette écriture par son créateur, Solomana Kanté.",
      ),
      Exercise.quizText(
        question: "Dans ߒߞߏ, quelle lettre est écrite EN PREMIER (à droite) ?",
        correctLabel: "ߒ (N)",
        options: shuffle(["ߒ (N)", "ߞ (K)", "ߏ (O)", "ߊ (A)"]),
        explanation: "Le N'Ko s'écrit de droite à gauche, donc la première lettre tracée est la plus à droite : ߒ (N).",
      ),
      Exercise.quizText(
        question: "Le N'Ko se lit et s'écrit dans quel sens ?",
        correctLabel: "De droite à gauche",
        options: shuffle(["De droite à gauche", "De gauche à droite", "De haut en bas", "Aucun sens fixe"]),
        explanation: "Comme l'arabe ou l'hébreu, le N'Ko se lit et s'écrit de droite à gauche — c'est pour cela que le texte est aligné à droite dans les exercices.",
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
    final explanation = dir == QuizDirection.charToSound
        ? "La lettre ${l.char} s'appelle ${l.name} et se prononce « ${l.sound} »."
        : "Le son « ${l.sound} » correspond à la lettre ${l.char}, qui s'appelle ${l.name}.";
    quizzes.add(Exercise.quizLetter(dir: dir, l: l, opts: buildOptions(l, pool), explanation: explanation));
  }
  final matchStep = Exercise.match(shuffle(letters).take(6).toList());

  // One listening rep (hear the sound, pick the letter) and one handwriting
  // rep (trace the first letter taught) per unit — features 16 and 18.
  final listeningLetter = letters.first;
  final listeningStep = Exercise.listening(
    l: listeningLetter,
    spokenText: listeningLetter.sound,
    opts: buildOptions(listeningLetter, pool),
  );
  final handwritingStep = Exercise.handwriting(listeningLetter);

  final shuffledQuizzes = shuffle(quizzes);
  // Mirrors Duolingo's lesson shape: teach each item, a matching-pairs
  // checkpoint, a listening + handwriting rep, then mixed recall questions.
  return [...intros, matchStep, listeningStep, handwritingStep, ...shuffledQuizzes];
}

const _extraMeaningDistractors = ["École", "Au revoir", "Combien ?", "Argent"];
const _extraNkoDistractors = ["ߒߞߏ", "߃", "߅", "ߊ"];

/// Word-level lesson shape for a [VocabWord] unit (as opposed to
/// [buildExercises]'s letter-level shape): teach each phrase, drill
/// reconstructing and pronouncing it, then mixed translation recall in both
/// directions — mirrors [translationExercises]'s question style.
List<Exercise> buildVocabExercises(List<VocabWord> words) {
  final drills = <Exercise>[Exercise.wordIntro()];
  for (final w in words) {
    final tiles = w.nko.split(' ');
    drills.add(Exercise.wordBank(
      question: "Reconstitue « ${w.meaning} » en touchant les mots dans le bon ordre",
      answer: tiles,
      tiles: shuffle(tiles),
    ));
    if (w.phonetic != null) {
      drills.add(Exercise.pronunciation(targetWord: w.nko, targetPhonetic: w.phonetic!));
    }
  }

  final quizzes = <Exercise>[];
  for (final w in words) {
    final meaningPool = shuffle([
      ...words.where((x) => x.meaning != w.meaning).map((x) => x.meaning),
      ..._extraMeaningDistractors,
    ]).take(3).toList();
    quizzes.add(Exercise.quizText(
      question: "Que veut dire « ${w.nko} » ?",
      correctLabel: w.meaning,
      options: shuffle([w.meaning, ...meaningPool]),
    ));

    final nkoPool = shuffle([
      ...words.where((x) => x.nko != w.nko).map((x) => x.nko),
      ..._extraNkoDistractors,
    ]).take(3).toList();
    quizzes.add(Exercise.quizText(
      question: "Comment dit-on « ${w.meaning} » en N'Ko ?",
      correctLabel: w.nko,
      options: shuffle([w.nko, ...nkoPool]),
    ));
  }

  return [...drills, ...shuffle(quizzes)];
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
