/// Règle du triangle : longueur maximale d'un câble S2 dérivé d'un câble S1
/// protégé par un disjoncteur P contre les courts-circuits minimaux.
library;

import '../donnees/courbes_disjoncteurs.dart';
import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

/// Tension simple et coefficient fixés dans le classeur (230 V × 0,8).
const double _tension = 230;
const double _coefficient = 0.8;

class ResultatTriangle {
  const ResultatTriangle({
    required this.longueurMaxS1,
    required this.longueurMaxS2Seul,
    required this.longueurMaxS2,
    required this.conforme,
  });

  /// Longueur maximale de S1 protégée par P (cellule P7), en mètres.
  final double longueurMaxS1;

  /// Longueur maximale de S2 si S2 partait directement de P (cellule R7).
  final double longueurMaxS2Seul;

  /// Longueur maximale de S2 dérivé à la distance donnée (cellule J7).
  final double longueurMaxS2;

  /// Longueur distribuée <= longueur maximale.
  final bool conforme;
}

/// Longueur maximale protégée : 0,8 × 230 × S / (2 × Ir × (Im/Ir) × ρ).
/// Pas de correctif 50 -> 47,5 dans cet onglet.
double longueurMaxProtegee({
  required double section,
  required Ame ame,
  required double ir,
  required double multiple,
}) =>
    (_tension * _coefficient * section) /
    (2 * ir * multiple * rhoChuteTension(ame));

ResultatTriangle calculerRegleTriangle({
  required ReglageMagnetique reglage,
  required double ir,
  required double sectionS1,
  required Ame ameS1,
  required double distancePS2,
  required double sectionS2,
  required Ame ameS2,
  required double longueurDistribuee,
}) {
  final m = reglage.multiple;
  final lg1 =
      longueurMaxProtegee(section: sectionS1, ame: ameS1, ir: ir, multiple: m);
  final lg2 =
      longueurMaxProtegee(section: sectionS2, ame: ameS2, ir: ir, multiple: m);
  final maxS2 = (lg1 - distancePS2) * (lg2 / lg1);
  return ResultatTriangle(
    longueurMaxS1: lg1,
    longueurMaxS2Seul: lg2,
    longueurMaxS2: maxS2,
    conforme: longueurDistribuee <= maxS2,
  );
}
