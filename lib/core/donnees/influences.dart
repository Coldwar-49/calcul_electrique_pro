/// Influences externes (codes AA, AD, AE… de la NF C 15-100) : glossaire et
/// modèle des seuils par type de câble ou de conduit.
library;

/// Règle d'un type de matériel pour une influence : à partir de quel niveau
/// l'influence devient contraignante.
class RegleInfluence {
  const RegleInfluence({this.min, this.max, this.exclus = const {}})
      : toujours = false;

  /// Influence toujours contraignante, quel que soit le niveau.
  const RegleInfluence.toujours()
      : min = null,
        max = null,
        exclus = const {},
        toujours = true;

  /// Contraignante si le niveau est inférieur à [min].
  final int? min;

  /// Contraignante si le niveau est supérieur à [max].
  final int? max;

  /// Niveaux contraignants pris isolément (ex. égal à 2).
  final Set<int> exclus;
  final bool toujours;

  bool contrainte(int niveau) =>
      toujours ||
      (max != null && niveau > max!) ||
      (min != null && niveau < min!) ||
      exclus.contains(niveau);
}

/// Condition sur le niveau d'une influence : `<`, `>` ou `=`.
class ConditionNiveau {
  const ConditionNiveau(this.code, this.operateur, this.valeur);
  final String code;
  final String operateur;
  final int valeur;

  bool verifie(Map<String, int> niveaux) {
    final n = niveaux[code];
    if (n == null) return false;
    return switch (operateur) {
      '<' => n < valeur,
      '>' => n > valeur,
      _ => n == valeur,
    };
  }
}

/// Remarque « Toléré si… », affichée quand toutes ses conditions sont vraies
/// (liste vide : toujours affichée).
class NoteInfluence {
  const NoteInfluence(this.texte, this.conditions);
  final String texte;
  final List<ConditionNiveau> conditions;

  bool applicable(Map<String, int> niveaux) =>
      conditions.every((c) => c.verifie(niveaux));
}

/// Type de câble ou de conduit avec ses seuils d'influences.
class TypeInfluence {
  const TypeInfluence({
    required this.nom,
    required this.usageCourant,
    required this.regles,
    this.contraintesFixes,
    this.notes = const [],
  });

  final String nom;

  /// Matériel d'usage courant (colonne « OUI/NON » du classeur).
  final bool usageCourant;

  /// Règle par code d'influence.
  final Map<String, RegleInfluence> regles;

  /// Si non nul, les influences contraignantes sont fixes (le classeur affiche
  /// un texte constant, par exemple « BC »).
  final List<String>? contraintesFixes;
  final List<NoteInfluence> notes;
}

/// Une influence externe et les libellés de ses niveaux (niveau 1 en premier).
class Influence {
  const Influence(this.code, this.titre, this.niveaux);
  final String code;
  final String titre;
  final List<String> niveaux;
}

/// Ordre d'affichage du classeur (en-tête de la ligne des niveaux).
const List<String> ordreSaisieInfluences = [
  'AE', 'AD', 'AG', 'BE', 'AA', 'AF', 'AH', 'AK', 'AL', 'BB', 'BC', 'BD', 'CA',
  'CB',
];

/// Niveaux par défaut du classeur (ligne 8).
const Map<String, int> niveauxParDefaut = {
  'AE': 1, 'AD': 1, 'AG': 1, 'BE': 1, 'AA': 4, 'AF': 1, 'AH': 1, 'AK': 1,
  'AL': 1, 'BB': 1, 'BC': 3, 'BD': 1, 'CA': 1, 'CB': 1,
};

/// Glossaire de l'onglet « Valeurs IP-IK ».
const Map<String, Influence> glossaireInfluences = {
  'AA': Influence('AA', 'Température ambiante', [
    '-60 à +5°C',
    '-40 à +5°C',
    '-25 à +5°C',
    '-5 à +40°C',
    '+5 à +40°C',
    '+5 à +60°C',
    '-25 à +55°C',
    '-50 à +40°C',
  ]),
  'AD': Influence('AD', 'Présence d\'eau', [
    'Négligeable',
    'Chutes de gouttes d\'eau',
    'Aspersion d\'eau',
    'Projection d\'eau',
    'Jets d\'eau',
    'Paquets d\'eau',
    'Immersion',
    'Submersion',
  ]),
  'AE': Influence('AE', 'Corps solides étrangers', [
    'Négligeable',
    'Petits objets',
    'Très petits objets',
    'Poussières',
  ]),
  'AF': Influence('AF', 'Corrosion', [
    'Négligeable',
    'Atmosphérique',
    'Intermittente / accidentelle',
    'Permanente',
  ]),
  'AG': Influence('AG', 'Chocs mécaniques', [
    'Faibles',
    'Moyens',
    'Importants',
    'Très importants',
  ]),
  'AH': Influence('AH', 'Vibrations', ['Faibles', 'Moyennes', 'Importantes']),
  'AK': Influence('AK', 'Flore ou moisissures', ['Négligeable', 'Risques']),
  'AL': Influence('AL', 'Faune', ['Négligeable', 'Risques']),
  'BB': Influence('BB', 'Résistance du corps', [
    'Normale',
    'Faible',
    'Très faible',
  ]),
  'BC': Influence('BC', 'Contact avec la terre', [
    'Nul',
    'Faible',
    'Fréquent',
    'Continu',
  ]),
  'BD': Influence('BD', 'Évacuation en cas d\'urgence', [
    'Normale',
    'Difficile',
    'Encombrée',
    'Difficile et encombrée',
  ]),
  'BE': Influence('BE', 'Nature des matières traitées ou entreposées', [
    'Négligeable',
    'Incendie',
    'Explosion',
    'Contamination',
  ]),
  'CA': Influence('CA', 'Matériaux de construction', [
    'Non combustibles',
    'Combustibles',
  ]),
  'CB': Influence('CB', 'Structure des bâtiments', [
    'Risques négligeables',
    'Propagation d\'incendie',
    'Mouvements',
    'Flexibles ou instables',
  ]),
};
