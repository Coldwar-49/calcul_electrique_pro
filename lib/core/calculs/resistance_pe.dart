/// Résistance maximale des conducteurs de protection (visite initiale),
/// schémas TN et IT, protection par disjoncteur ou par fusible.
/// Résultats en milliohms.
library;

import '../donnees/courbes_disjoncteurs.dart';
import '../donnees/fusibles.dart';

/// Rmax selon le régime de neutre.
class ResistancesPe {
  const ResistancesPe({
    required this.tn,
    required this.itan,
    required this.itsn,
  });

  /// À partir de la valeur TN : ITAN = × 0,5 ; ITSN = × 0,866.
  factory ResistancesPe.depuisTn(double tn) =>
      ResistancesPe(tn: tn, itan: tn * 0.5, itsn: tn * 0.866);

  final double tn;
  final double itan;
  final double itsn;

  ResistancesPe multiplie(double f) =>
      ResistancesPe(tn: tn * f, itan: itan * f, itsn: itsn * f);
}

/// Résultat pour un fusible : circuits terminaux et divisionnaires.
class ResistancesPeFusible {
  const ResistancesPeFusible({
    required this.ia,
    required this.terminaux,
    required this.divisionnaires,
  });

  /// Courant de fusion Ia (A).
  final double ia;
  final ResistancesPe terminaux;
  final ResistancesPe divisionnaires;
}

/// k2 selon le rapport Sph/Spe : 1 -> 1, 2 -> 1,33, 3 -> 1,5.
double k2Rapport(int rapport) => switch (rapport) {
      1 => 1,
      2 => 1.33,
      3 => 1.5,
      _ => throw ArgumentError('Rapport Sph/Spe $rapport hors 1, 2 ou 3'),
    };

/// Petits disjoncteurs : Rmax = 1000 × U0 × k2 / (2 × m × Ir),
/// m étant le multiple de la courbe.
ResistancesPe resistanceMaxPetitDisjoncteur({
  required double u0,
  required CourbeDisjoncteur courbe,
  required double ir,
  required int rapportSphSpe,
}) =>
    ResistancesPe.depuisTn(
        1000 * u0 * k2Rapport(rapportSphSpe) / (2 * courbe.multiple * ir));

/// Disjoncteurs industriels : Rmax = U0 × 1000 × k2 / (2 × multiple × Ir).
/// Le multiple saisi est utilisé tel quel (sans le facteur 1,2).
ResistancesPe resistanceMaxDisjoncteurIndustriel({
  required double u0,
  required double multipleIr,
  required double ir,
  required int rapportSphSpe,
}) =>
    ResistancesPe.depuisTn(
        u0 * 1000 * k2Rapport(rapportSphSpe) / (2 * multipleIr * ir));

/// Fusibles : Rmax = 1000 × U0 × k2 / (2 × Ia), puis coefficient pour les
/// circuits divisionnaires (1,88 pour gG, 1,53 pour aM).
ResistancesPeFusible resistanceMaxFusible({
  required double u0,
  required TypeFusible type,
  required double calibre,
  required int rapportSphSpe,
}) {
  final ia = courantIa(type, calibre);
  final terminaux = ResistancesPe.depuisTn(
      1000 * u0 * k2Rapport(rapportSphSpe) / (2 * ia));
  return ResistancesPeFusible(
    ia: ia,
    terminaux: terminaux,
    divisionnaires: terminaux.multiplie(type.coefficientDivisionnaire),
  );
}

/// Calculatrice du classeur : Ir = In × facteur 1 × facteur 2
/// (exemple : 200 × 0,9 × 0,93 = 167,4 A).
double calculerIr({
  required double courantNominal,
  required double facteur1,
  required double facteur2,
}) =>
    courantNominal * facteur1 * facteur2;
