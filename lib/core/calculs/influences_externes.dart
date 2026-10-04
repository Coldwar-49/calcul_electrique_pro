/// Influences externes : câbles et conduits adaptés aux conditions d'emploi
/// (onglets « IP-IK Cables » et « IP-IK Conduits »).
///
/// Ne calcule pas les indices IP / IK requis : le classeur les affiche sans
/// formule (valeurs saisies par macro), ils ne sont donc pas reproduits.
library;

import '../donnees/influences.dart';
import '../donnees/influences_2024.dart';
import '../donnees/types.dart';

/// Ordre dans lequel le classeur concatène les influences contraignantes.
const List<String> ordreContraintes = [
  'AA', 'AD', 'AE', 'AF', 'AG', 'AH', 'AK', 'AL', 'BB', 'BC', 'BD', 'BE', 'CA',
  'CB',
];

class ResultatInfluences {
  const ResultatInfluences({
    required this.type,
    required this.contraintes,
    required this.remarques,
  });

  final TypeInfluence type;

  /// Codes des influences qui rendent le matériel inadapté.
  final List<String> contraintes;

  /// Remarques « Toléré si… » applicables aux niveaux saisis.
  final List<String> remarques;

  bool get convient => contraintes.isEmpty;
}

/// Évalue un type de câble ou de conduit pour les [niveaux] saisis
/// (code d'influence -> niveau, 1 pour le premier).
ResultatInfluences evaluerType(TypeInfluence type, Map<String, int> niveaux) {
  final List<String> contraintes;
  if (type.contraintesFixes != null) {
    contraintes = type.contraintesFixes!;
  } else {
    contraintes = [
      for (final code in ordreContraintes)
        if (type.regles[code] != null &&
            niveaux[code] != null &&
            type.regles[code]!.contrainte(niveaux[code]!))
          code,
    ];
  }
  final remarques = <String>[];
  for (final n in type.notes) {
    if (n.applicable(niveaux) && !remarques.contains(n.texte)) {
      remarques.add(n.texte);
    }
  }
  return ResultatInfluences(
    type: type,
    contraintes: contraintes,
    remarques: remarques,
  );
}

/// [edition] : `normeActuelle` = tableaux 52.3A / 52.4 de la NF C 15-100-1
/// (2024), `norme2013` = classeur.
List<ResultatInfluences> evaluerCables(
  Map<String, int> niveaux, {
  EditionNorme edition = EditionNorme.normeActuelle,
}) =>
    [for (final t in cablesPourEdition(edition)) evaluerType(t, niveaux)];

List<ResultatInfluences> evaluerConduits(
  Map<String, int> niveaux, {
  EditionNorme edition = EditionNorme.normeActuelle,
}) =>
    [for (final t in conduitsPourEdition(edition)) evaluerType(t, niveaux)];
