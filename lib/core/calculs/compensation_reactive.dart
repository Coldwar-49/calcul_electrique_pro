/// Compensation d'énergie réactive : Qc = P × (tan φ1 − tan φ2).
/// Formule de base (hors classeur CLAUREG).
library;

import 'dart:math' as math;

class ResultatCompensation {
  const ResultatCompensation({
    required this.puissanceBatterie,
    required this.reactifAvant,
    required this.reactifApres,
    required this.apparenteAvant,
    required this.apparenteApres,
  });

  /// Qc en var (négatif si le cos φ visé est inférieur à l'actuel).
  final double puissanceBatterie;
  final double reactifAvant;
  final double reactifApres;
  final double apparenteAvant;
  final double apparenteApres;
}

double _tanPhi(double cosPhi) => math.sqrt(1 - cosPhi * cosPhi) / cosPhi;

/// [puissance] en watts ; cos φ dans ]0 ; 1].
ResultatCompensation calculerCompensation({
  required double puissance,
  required double cosPhiActuel,
  required double cosPhiVise,
}) {
  final q1 = puissance * _tanPhi(cosPhiActuel);
  final q2 = puissance * _tanPhi(cosPhiVise);
  return ResultatCompensation(
    puissanceBatterie: q1 - q2,
    reactifAvant: q1,
    reactifApres: q2,
    apparenteAvant: puissance / cosPhiActuel,
    apparenteApres: puissance / cosPhiVise,
  );
}
