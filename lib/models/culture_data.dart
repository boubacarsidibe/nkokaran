/// Cultural content — proverbs and short culture notes shown alongside the
/// lessons/episodes, plus the audio glossary's word list.
library;

import 'nko_data.dart';

class CultureCard {
  final String episodeId;
  final String title;
  final String body;
  const CultureCard({required this.episodeId, required this.title, required this.body});
}

const cultureCards = <CultureCard>[
  CultureCard(
    episodeId: "ep1",
    title: "Le marché, cœur de la vie manding",
    body: "Dans les villes et villages manding (Guinée, Mali, Côte d'Ivoire, Burkina Faso…), le marché "
        "n'est pas qu'un lieu d'achat : c'est là qu'on échange les nouvelles, qu'on négocie en plaisantant, "
        "et qu'on entend se croiser plusieurs langues et dialectes — bambara, maninka, dioula — dans une "
        "même journée. Marchander poliment, comme le fait Sekou, est perçu comme un signe de respect envers "
        "le vendeur, pas comme de la méfiance.",
  ),
  CultureCard(
    episodeId: "ep2",
    title: "Des chiffres propres au N'Ko",
    body: "Quand Solomana Kanté a créé l'alphabet N'Ko en 1949, il lui a donné son propre système de "
        "chiffres (߀ à ߉), distinct des chiffres arabo-indiens utilisés en français. Compter en N'Ko, "
        "comme le fait Moussa avec Sekou, fait donc partie intégrante de l'écriture elle-même — ce n'est "
        "pas un simple emprunt à une autre langue.",
  ),
  CultureCard(
    episodeId: "ep3",
    title: "Revenir, c'est saluer deux fois",
    body: "Retourner voir le même vendeur, comme le fait Sekou avec Moussa, est courant sur les marchés "
        "manding : la fidélité à un étal se construit sur plusieurs visites, et chaque retour commence par "
        "les mêmes salutations complètes — jamais un simple signe de tête. Sauter les politesses, même pour "
        "quelqu'un qu'on a déjà rencontré la veille, serait perçu comme un manque de respect.",
  ),
];

CultureCard? cultureCardForEpisode(String episodeId) {
  for (final c in cultureCards) {
    if (c.episodeId == episodeId) return c;
  }
  return null;
}

class Proverb {
  final String unitId;
  final String nko;
  final String transliteration;
  final String translation;
  final String explanation;
  const Proverb({
    required this.unitId,
    required this.nko,
    required this.transliteration,
    required this.translation,
    required this.explanation,
  });
}

const proverbs = <Proverb>[
  Proverb(
    unitId: "u1",
    nko: "ߊ߬ ߕߍ߫ ߞߐ߲߬ߘߐ߲߬ ߠߊ߫ ߝߊ߲߬ߞߋߟߋ߲ ߘߐ߫.",
    transliteration: "A tɛ kɔnkɔn na fan kelen dɔ.",
    translation: "On ne frappe pas un tam-tam d'un seul côté.",
    explanation: "Toute chose a plusieurs facettes — invite à écouter les deux côtés d'une histoire avant de juger.",
  ),
  Proverb(
    unitId: "u2",
    nko: "ߓߊߘߋ߲ ߕߍ߫ ߛߊ߲ ߘߐ߫, ߓߊ߬ߙߊ ߦߋ߫ ߘߎ߱ ߘߐ߫.",
    transliteration: "Baden tɛ san kɔnɔ, baraji bɛ dugu kɔnɔ.",
    translation: "Un frère n'habite pas dans le ciel, l'entraide se trouve sur terre.",
    explanation: "Rappelle l'importance de la solidarité concrète, entre proches, ici-bas.",
  ),
  Proverb(
    unitId: "u3",
    nko: "ߞߏ ߡߊ߫ ߣߌ߲߬ߣߌ߲߬, ߊ߬ ߦߴߊ߬ ߡߊ߬ ߞߏ ߘߌ߫.",
    transliteration: "Ko ma nyinnyin, a bɛ a ma ko di.",
    translation: "Une chose qui n'est pas encore arrivée peut toujours arriver.",
    explanation: "Un appel à rester prudent et préparé, même quand tout semble calme.",
  ),
  Proverb(
    unitId: "u4",
    nko: "ߝߊ߬ ߞߊ߲ ߕߍ߫ ߕߌ߲ ߘߐ߫.",
    transliteration: "Fa kan tɛ tɛn kɔnɔ.",
    translation: "La parole d'un père ne tombe pas dans le vide.",
    explanation: "Le conseil des aînés garde toujours son poids, même longtemps après avoir été donné.",
  ),
  Proverb(
    unitId: "u5",
    nko: "ߣߌ߫ ߌ ߡߊ߫ ߘߏ߲߬ ߛߎ ߘߐ߫, ߌ ߕߍ߫ ߣߎ߲ ߠߎ߬ ߟߐ߲߫.",
    transliteration: "Ni i ma don su kɔnɔ, i tɛ suruku dɔn.",
    translation: "Si tu n'entres pas dans la brousse la nuit, tu ne connaîtras jamais l'hyène.",
    explanation: "On n'apprend vraiment les choses difficiles qu'en s'y confrontant soi-même.",
  ),
  Proverb(
    unitId: "u6",
    nko: "ߞߋߟߋ߲ ߕߍ߫ ߞߍ߫ ߓߏ߬ߟߏ߲ ߘߌ߫.",
    transliteration: "Kelen tɛ kɛ bolon di.",
    translation: "Un seul doigt ne fait pas un poing.",
    explanation: "L'union fait la force — souvent cité pour parler d'entraide communautaire, un thème repris dans le comptage collectif.",
  ),
  Proverb(
    unitId: "u7",
    nko: "ߞߊ߲ ߘߌ߫ ߕߐ߯ ߛߣߍ߫, ߊ߬ ߕߍ߫ ߛߊ߬.",
    transliteration: "Kan bɛ se ka to sen na, a tɛ sa.",
    translation: "Une langue peut rester debout — elle ne meurt pas.",
    explanation: "Souvent cité pour parler de la transmission des langues : tant qu'on la parle et qu'on l'écrit, une langue comme celle portée par le N'Ko continue de vivre.",
  ),
];

Proverb? proverbForUnit(String unitId) {
  for (final p in proverbs) {
    if (p.unitId == unitId) return p;
  }
  return null;
}

/// One chapter of the "Histoire du N'Ko" screen — biography of Solomana
/// Kanté and the story of the script, sourced from Wikipédia (FR/EN) and
/// manden.org. Kept as plain French prose (no invented N'Ko sentences).
class HistoryChapter {
  final String title;
  final String body;
  const HistoryChapter({required this.title, required this.body});
}

const historyChapters = <HistoryChapter>[
  HistoryChapter(
    title: "Qui était Solomana Kanté ?",
    body: "Solomana Kanté (aussi écrit Souleymane Kanté) est né en 1922 à Koloni, "
        "près de Kankan, en Guinée. Fils d'un érudit qui dirigeait une école coranique, "
        "il quitte la Guinée pour la Côte d'Ivoire en 1941 après la mort de son père, "
        "et devient commerçant tout en poursuivant seul son instruction. Il meurt le "
        "23 novembre 1987 à Conakry.",
  ),
  HistoryChapter(
    title: "Une réponse à un article",
    body: "En 1949, à Bingerville, Kanté lit un article du journaliste libanais Kamel "
        "Marouah affirmant que les langues africaines, faute d'écriture propre, ne "
        "pouvaient pas exprimer de pensée abstraite ni de règles grammaticales. "
        "Convaincu du contraire, et après plusieurs essais infructueux pour transcrire "
        "le maninka avec les alphabets arabe et latin — mal adaptés aux sons et aux tons "
        "des langues manding — il décide de créer un système d'écriture entièrement "
        "nouveau.",
  ),
  HistoryChapter(
    title: "La naissance du N'Ko, le 14 avril 1949",
    body: "Après plusieurs années de recherche, Kanté achève son alphabet le 14 avril "
        "1949 et le baptise ߒߞߏ (n'ko), qui signifie « je dis » dans l'ensemble des "
        "langues manding. Cette date est depuis célébrée chaque année comme la Journée "
        "de l'alphabet N'Ko. Le N'Ko s'écrit de droite à gauche, comme l'arabe, mais — "
        "à la différence de celui-ci — il note obligatoirement les voyelles et les tons, "
        "ce qui le rend particulièrement adapté à la phonologie des langues manding.",
  ),
  HistoryChapter(
    title: "De Bingerville à Kankan",
    body: "Kanté rapporte son alphabet à Kankan, sa ville natale, où il enseigne le "
        "N'Ko et rédige les premiers manuels. En 38 ans, il écrira plus d'une "
        "soixantaine d'ouvrages : syllabaires, grammaires, recueils de proverbes et de "
        "poésie, traductions religieuses (dont des extraits du Coran), un dictionnaire, "
        "et des textes sur l'histoire manding et la médecine traditionnelle — posant les "
        "bases d'une véritable littérature écrite en N'Ko.",
  ),
  HistoryChapter(
    title: "Le N'Ko aujourd'hui",
    body: "Porté par des associations d'alphabétisation dans toute l'Afrique de "
        "l'Ouest — Guinée, Mali, Côte d'Ivoire, Sénégal, Burkina Faso — et par une "
        "diaspora active, le N'Ko continue de se diffuser : journaux, sites web, "
        "manuels scolaires et, depuis 2006, son propre bloc Unicode (U+07C0–U+07FF), "
        "qui permet d'écrire le N'Ko sur ordinateurs et téléphones, exactement comme "
        "dans cette application.",
  ),
];

class GlossaryEntry {
  final String nko;
  final String latin;
  final String meaning;
  const GlossaryEntry({required this.nko, required this.latin, required this.meaning});
}

/// Audio glossary content — every letter/digit already taught, plus the
/// handful of words introduced in the lessons and the first story episode.
final glossaryEntries = <GlossaryEntry>[
  for (final l in allLettersAndDigits) GlossaryEntry(nko: l.char, latin: l.name, meaning: "se prononce « ${l.sound} »"),
  const GlossaryEntry(nko: "ߒߞߏ", latin: "n-ko", meaning: '"je dis" — le nom de l\'écriture'),
  const GlossaryEntry(nko: "ߌ ߣߌ߫ ߛߐ߬ߘߐ߲߬", latin: "i ni sɔgɔma", meaning: "bonjour"),
  const GlossaryEntry(nko: "ߌ ߣߌ߫ ߖߊ߬ߣߍ߲", latin: "i ni sɛnɛ", meaning: "merci"),
  const GlossaryEntry(nko: "ߡߊ߲߬ߜ", latin: "mangɛ", meaning: "mangue"),
];
