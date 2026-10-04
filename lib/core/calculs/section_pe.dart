/// Section du conducteur de protection (PE).
///
/// Tableau 3 : NF C 15-100-1 (août 2024), partie 5-54, art. 543.1, tableau
/// 54.3 (identique au tableau 3 du guide UTE C 15-106 de 2003).
/// Formule S = √(I²t) / k, valeurs de k et minima hors canalisation (2,5 / 4 /
/// 35 mm²) : guide UTE C 15-106 (2003), §4.1 et §4.4, à confirmer dans les
/// tableaux 54A.2 à 54A.6 et l'art. 543.1.3 de l'édition 2024 (voir
/// docs/changements_nfc15100.md).
library;

import 'dart:math' as math;

import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

/// Sections normalisées (mm²) servant à arrondir « à la section supérieure ».
final List<double> sectionsNormalisees = sectionsUsuelles;

/// Plus petite section normalisée ≥ [valeur] (la dernière si dépassement).
double sectionNormaliseeSuperieure(double valeur) {
  for (final s in sectionsNormalisees) {
    if (s >= valeur - 1e-9) return s;
  }
  return sectionsNormalisees.last;
}

/// Tableau 3, colonne « même nature que la phase » : S jusqu'à 16 mm², puis
/// 16 mm² jusqu'à 35 mm², puis S/2. Avec un PE de nature différente, la valeur
/// est multipliée par k1 / k2 (k1 : phase, k2 : conducteur de protection).
double sectionPeTableau3(double sectionPhase) {
  if (sectionPhase <= 16) return sectionPhase;
  if (sectionPhase <= 35) return 16;
  return sectionPhase / 2;
}

/// Minimum d'un PE qui ne fait pas partie de la canalisation d'alimentation.
/// Cuivre : 2,5 mm² protégé mécaniquement, 4 mm² sinon ; aluminium : 35 mm².
double minimumHorsCanalisation(Ame ame, {required bool protegeMecaniquement}) =>
    ame == Ame.aluminium ? 35 : (protegeMecaniquement ? 2.5 : 4);

/// Section minimale par la contrainte thermique : S = √(I²t) / k.
/// [ikA] en ampères, [temps] en secondes (≤ 5 s).
double sectionPeThermique({
  required double ikA,
  required double temps,
  required double k,
}) => math.sqrt(ikA * ikA * temps) / k;

class ResultatSectionPe {
  const ResultatSectionPe({
    required this.tableau3,
    required this.minimumMecanique,
    required this.thermique,
    required this.calculee,
    required this.retenue,
    required this.k2Utilise,
  });

  /// Section issue du tableau 3 (avec k1/k2 si métaux différents).
  final double tableau3;

  /// Minimum hors canalisation (0 si le PE est dans la canalisation).
  final double minimumMecanique;

  /// Section thermique √(I²t)/k, `null` si Ik et t ne sont pas fournis.
  final double? thermique;

  /// Plus grande des trois exigences, avant arrondi.
  final double calculee;

  /// Section normalisée supérieure ou égale à [calculee].
  final double retenue;

  /// Valeur de k2 effectivement utilisée.
  final double k2Utilise;
}

/// Section minimale du PE : plus grande des exigences du tableau 3, du minimum
/// hors canalisation et, si [ikA] et [temps] sont donnés, de la contrainte
/// thermique (avec [k2]).
///
/// [k2Gros] : valeur de k2 applicable si le PE dépasse 300 mm² (conducteur
/// isolé) ; le calcul est refait avec elle quand la section retenue la dépasse.
ResultatSectionPe calculerSectionPe({
  required double sectionPhase,
  required Ame amePhase,
  required Ame amePe,
  double k1 = 1,
  double k2 = 1,
  double? k2Gros,
  bool horsCanalisation = false,
  bool protegeMecaniquement = true,
  double? ikA,
  double? temps,
}) {
  ResultatSectionPe calcul(double k) {
    final t3 = amePhase == amePe
        ? sectionPeTableau3(sectionPhase)
        : sectionPeTableau3(sectionPhase) * k1 / k;
    final mini = horsCanalisation
        ? minimumHorsCanalisation(
            amePe,
            protegeMecaniquement: protegeMecaniquement,
          )
        : 0.0;
    final th = (ikA != null && temps != null)
        ? sectionPeThermique(ikA: ikA, temps: temps, k: k)
        : null;
    final calculee = [t3, mini, th ?? 0.0].reduce(math.max);
    return ResultatSectionPe(
      tableau3: t3,
      minimumMecanique: mini,
      thermique: th,
      calculee: calculee,
      retenue: sectionNormaliseeSuperieure(calculee),
      k2Utilise: k,
    );
  }

  final r = calcul(k2);
  if (k2Gros != null && k2Gros != k2 && r.retenue > 300) {
    return calcul(k2Gros);
  }
  return r;
}
