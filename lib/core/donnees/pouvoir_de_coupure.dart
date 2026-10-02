/// Tables de pouvoir de coupure (Pdc) du classeur, onglets « Pdc 1 pole IT »,
/// « PDC Fusibles » et « PDC DM Schneider ». Valeurs en kA, recopiées telles
/// quelles : aucune règle de calcul n'est ajoutée.
library;

import 'fusibles.dart';

// ------------------------------------------------- Pdc sous un pôle (IT)

/// Gamme de disjoncteurs et son pouvoir de coupure sous un pôle (schéma IT).
class GammeIt {
  const GammeIt(this.libelle, this.pdcKa);
  final String libelle;
  final double pdcKa;
}

const List<GammeIt> gammesIt = [
  GammeIt('DT 40', 2),
  GammeIt('DT 40N', 2),
  GammeIt('C60N', 3),
  GammeIt('C60L (≤ 25 A)', 6),
  GammeIt('C60L (≤ 40 A)', 5),
  GammeIt('C60L (≤ 63 A)', 4),
  GammeIt('C60H', 4),
  GammeIt('C120N', 3),
  GammeIt('C120H', 4.5),
  GammeIt('NG125N', 6),
  GammeIt('NG125L', 12.5),
  GammeIt('C60LMA (≤ 25 A)', 6),
  GammeIt('C60LMA (40 A)', 5),
  GammeIt('NG125LMA', 12.5),
];

// ------------------------------------------------- fusibles cylindriques

/// Plage de calibres (A) d'un fusible et son pouvoir de coupure (kA).
class PlageFusible {
  const PlageFusible(this.calibreMin, this.calibreMax, this.pdcKa);
  final double calibreMin;
  final double calibreMax;
  final double pdcKa;

  bool contient(double calibre) =>
      calibre >= calibreMin && calibre <= calibreMax;
}

/// Taille de fusible cylindrique avec ses plages gG et aM.
class TailleFusible {
  const TailleFusible(this.libelle, this.gg, this.am);
  final String libelle;
  final PlageFusible gg;
  final PlageFusible am;

  PlageFusible plage(TypeFusible type) => type == TypeFusible.gg ? gg : am;
}

const List<TailleFusible> taillesFusibles = [
  TailleFusible('8,5 x 31,5', PlageFusible(1, 16, 20), PlageFusible(1, 10, 20)),
  TailleFusible(
      '10 x 38', PlageFusible(0.25, 25, 120), PlageFusible(0.25, 25, 100)),
  TailleFusible('14 x 51', PlageFusible(2, 50, 120), PlageFusible(2, 50, 100)),
  TailleFusible(
      '22 x 58', PlageFusible(4, 125, 120), PlageFusible(16, 125, 100)),
];

/// Les fusibles à couteaux ont un pouvoir de coupure de 120 kA.
const double pdcFusiblesCouteauxKa = 120;

// -------------------------------------- disjoncteurs moteurs Schneider

/// Disjoncteur moteur (catalogue 2009) et son pouvoir de coupure.
class DisjoncteurMoteur {
  const DisjoncteurMoteur(this.reference, this.pdcKa);
  final String reference;

  /// `double.infinity` pour « Pdc infini ».
  final double pdcKa;
}

const List<DisjoncteurMoteur> disjoncteursMoteurs = [
  DisjoncteurMoteur('GV2 ME 01 à 08, 10, 14', 100),
  DisjoncteurMoteur('GV2 ME 16, 20 à 22', 15),
  DisjoncteurMoteur('GV2 ME 32', 10),
  DisjoncteurMoteur('GV2 P 01 à 08, 10, 14, 16', 100),
  DisjoncteurMoteur('GV2 P 20 à 22', 50),
  DisjoncteurMoteur('GV2 P 32', 35),
  DisjoncteurMoteur('GV3 P 13, 18, 25, 32', 100),
  DisjoncteurMoteur('GV3 P 40, 50, 65', 50),
  DisjoncteurMoteur('GV3 ME 80', 15),
  DisjoncteurMoteur('GV2LE 03 à 08, 10, 14', 100),
  DisjoncteurMoteur('GV2LE 16, 20, 22', 15),
  DisjoncteurMoteur('GV2 LE 32', 10),
  DisjoncteurMoteur('GV2L 03 à 08, 10, 14', 100),
  DisjoncteurMoteur('GV2L 16, 20, 22', 50),
  DisjoncteurMoteur('GV2 L 32', 35),
  DisjoncteurMoteur('GV3 L 25, 32', 100),
  DisjoncteurMoteur('GV3 L 40, 50, 65', 50),
  DisjoncteurMoteur('GK3 EF 80', 35),
  DisjoncteurMoteur('P25M 0,16 à 10A 14 et 18A (230V)', double.infinity),
  DisjoncteurMoteur('P25M 14 à 25A (400V)', 15),
  DisjoncteurMoteur('P25M 23 et 25A (230V)', 50),
];
