/// Valeur maximale de la résistance de la prise de terre des masses selon le
/// courant différentiel-résiduel assigné du DDR, NF C 15-100-1 (2024-08),
/// tableau 53.1 (UL = 50 V : R = 50 / IΔn, valeurs arrondies par la norme).
library;

/// (IΔn en ampères, résistance maximale en ohms).
const List<(double, double)> tableau531 = [
  (20, 2.5),
  (10, 5),
  (5, 10),
  (3, 17),
  (1, 50),
  (0.5, 100),
  (0.3, 167),
  (0.1, 500),
];

/// Limite pratique du tableau pour la haute sensibilité (30 mA) : la norme
/// indique « > 500 Ω » plutôt que 1 667 Ω.
const double resistanceHauteSensibilite = 500;

/// Valeur du tableau 53.1 pour [idnAmperes], ou `null` si ce courant n'est pas
/// une ligne du tableau. Pour 30 mA, la valeur renvoyée est la limite
/// pratique 500 Ω (le tableau indique « > 500 »).
double? resistanceTableau531(double idnAmperes) {
  if ((idnAmperes - 0.03).abs() < 1e-9) return resistanceHauteSensibilite;
  for (final (i, r) in tableau531) {
    if ((i - idnAmperes).abs() < 1e-9) return r;
  }
  return null;
}
