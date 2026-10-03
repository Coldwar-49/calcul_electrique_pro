/// Courant d'emploi Ib d'un récepteur à partir de sa puissance.
/// Formules de base (hors classeur CLAUREG) : mono P / (U·cos φ),
/// triphasé P / (√3·U·cos φ), puissance absorbée = Pn / rendement.
library;

import 'dart:math' as math;

enum Alimentation {
  monophase('Monophasé (phase + neutre)', 230),
  triphase('Triphasé', 400);

  const Alimentation(this.libelle, this.tensionUsuelle);
  final String libelle;
  final double tensionUsuelle;
}

/// [puissance] en watts (puissance utile pour un moteur). [rendement] vaut 1
/// pour un récepteur dont la puissance donnée est déjà la puissance absorbée.
double courantEmploi({
  required Alimentation alimentation,
  required double puissance,
  required double tension,
  required double cosPhi,
  double rendement = 1,
}) {
  final absorbee = puissance / rendement;
  final diviseur = alimentation == Alimentation.triphase
      ? math.sqrt(3) * tension * cosPhi
      : tension * cosPhi;
  return absorbee / diviseur;
}
