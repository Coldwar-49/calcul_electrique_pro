/// Courants admissibles des câbles dans des conduits enterrés (méthode de
/// référence D1), NF C 15-100-1 (2024-08), tableau 52.8H.1 (capture fournie par
/// l'utilisateur, relue à l'écran), et groupement de conduits (tableau 52.17,
/// cas A : câbles multiconducteurs, un câble par conduit).
///
/// Valables pour un sol à 20 °C et 2,5 K·m/W ; les tableaux 52.10 et 52.11
/// (colonne « câble en conduit ») s'y appliquent.
library;

import 'types.dart';

// Colonnes : PVC 3 conducteurs chargés, PVC 2, PR 3, PR 2. Pas de valeur
// au-delà de 300 mm² ni, en aluminium, en dessous de 10 mm².
final Map<double, List<double>> _cuivre = {
  1.5: [18, 22, 21, 25],
  2.5: [24, 29, 28, 33],
  4: [30, 37, 36, 43],
  6: [38, 46, 44, 53],
  10: [50, 60, 58, 71],
  16: [64, 78, 75, 91],
  25: [82, 99, 96, 116],
  35: [98, 119, 115, 139],
  50: [116, 140, 135, 164],
  70: [143, 173, 167, 203],
  95: [169, 204, 197, 239],
  120: [192, 231, 223, 271],
  150: [217, 261, 251, 306],
  185: [243, 292, 281, 343],
  240: [280, 336, 324, 395],
  300: [316, 379, 365, 446],
};

final Map<double, List<double>> _aluminium = {
  10: [39, 47, 46, 55],
  16: [50, 61, 59, 71],
  25: [64, 77, 75, 90],
  35: [77, 93, 90, 108],
  50: [91, 109, 106, 128],
  70: [112, 135, 130, 158],
  95: [132, 159, 154, 186],
  120: [150, 180, 174, 211],
  150: [169, 204, 197, 238],
  185: [190, 228, 220, 267],
  240: [218, 262, 253, 307],
  300: [247, 296, 286, 346],
};

/// Courant admissible (A) d'un câble en conduit enterré (D1), ou `null` si la
/// section n'est pas au tableau.
double? courantD1(Ame ame, Isolant isolant, Circuit circuit, double section) {
  final ligne = (ame == Ame.cuivre ? _cuivre : _aluminium)[section];
  if (ligne == null) return null;
  final colonne = (isolant == Isolant.pvc ? 0 : 2) +
      (circuit == Circuit.triphase ? 0 : 1);
  return ligne[colonne];
}

/// Distance entre conduits enterrés (tableau 52.17).
enum DistanceConduits { nulle, m025, m05, m1 }

// Tableau 52.17 A : colonnes jointifs, 0,25 m, 0,5 m, 1,0 m ; 2 à 20 câbles.
const Map<int, List<double>> _t5217A = {
  2: [0.85, 0.90, 0.95, 0.95],
  3: [0.75, 0.85, 0.90, 0.95],
  4: [0.70, 0.80, 0.85, 0.90],
  5: [0.65, 0.80, 0.85, 0.90],
  6: [0.60, 0.80, 0.80, 0.90],
  7: [0.57, 0.76, 0.80, 0.88],
  8: [0.54, 0.74, 0.78, 0.88],
  9: [0.52, 0.73, 0.77, 0.87],
  10: [0.49, 0.72, 0.76, 0.86],
  11: [0.47, 0.70, 0.75, 0.86],
  12: [0.45, 0.69, 0.74, 0.85],
  13: [0.44, 0.68, 0.73, 0.85],
  14: [0.42, 0.68, 0.72, 0.84],
  15: [0.41, 0.67, 0.72, 0.84],
  16: [0.39, 0.66, 0.71, 0.83],
  17: [0.38, 0.65, 0.70, 0.83],
  18: [0.37, 0.65, 0.70, 0.83],
  19: [0.35, 0.64, 0.69, 0.82],
  20: [0.34, 0.63, 0.68, 0.82],
};

/// Groupement de [nombre] conduits enterrés (un câble multiconducteur par
/// conduit). Au-delà de 20, la ligne de 20.
double k5217A(int nombre, DistanceConduits distance) {
  if (nombre < 1) throw ArgumentError('Nombre >= 1 requis');
  if (nombre == 1) return 1;
  final ligne = _t5217A[nombre > 20 ? 20 : nombre]!;
  return ligne[distance.index];
}
