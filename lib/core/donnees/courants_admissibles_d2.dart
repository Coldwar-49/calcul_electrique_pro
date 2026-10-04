/// Courants admissibles des câbles directement enterrés (méthode de référence
/// D2), NF C 15-100-1 (2024-08), tableau 52.8H.2.
///
/// Valables pour une température du sol de 20 °C et une résistivité thermique
/// du sol de 2,5 K·m/W ; les facteurs des tableaux 52.10 (température du sol)
/// et 52.11 (résistivité) s'y appliquent. Tolérance de la norme : 5 %.
library;

import 'types.dart';

/// Sections du tableau (mm²).
const List<double> sectionsD2 = [
  1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300,
];

// Ordre des colonnes : PVC 3 conducteurs chargés, PVC 2, PR 3, PR 2.
final Map<double, List<int>> _cuivre = {
  1.5: [19, 22, 23, 27],
  2.5: [24, 28, 30, 35],
  4: [33, 38, 39, 46],
  6: [41, 48, 49, 58],
  10: [54, 64, 65, 77],
  16: [70, 83, 84, 100],
  25: [92, 110, 107, 129],
  35: [110, 132, 129, 155],
  50: [130, 156, 153, 183],
  70: [162, 192, 188, 225],
  95: [193, 230, 226, 270],
  120: [220, 261, 257, 306],
  150: [246, 293, 287, 343],
  185: [278, 331, 324, 387],
  240: [320, 382, 375, 448],
  300: [359, 427, 419, 502],
};

// Aluminium : pas de valeur à 10 mm² (la section minimale est 16 mm² dans le
// tableau) ni en dessous.
final Map<double, List<int>> _aluminium = {
  16: [53, 63, 64, 76],
  25: [69, 82, 82, 98],
  35: [83, 98, 98, 117],
  50: [99, 117, 117, 139],
  70: [122, 145, 144, 170],
  95: [148, 173, 172, 204],
  120: [169, 200, 197, 233],
  150: [189, 224, 220, 261],
  185: [214, 255, 250, 296],
  240: [250, 298, 290, 343],
  300: [282, 336, 326, 386],
};

/// Courant admissible (A) d'un câble enterré directement (D2), ou `null` si
/// la section n'est pas au tableau (moins de 16 mm² en aluminium, plus de
/// 300 mm²).
double? courantD2(Ame ame, Isolant isolant, Circuit circuit, double section) {
  final ligne = (ame == Ame.cuivre ? _cuivre : _aluminium)[section];
  if (ligne == null) return null;
  final colonne = (isolant == Isolant.pvc ? 0 : 2) +
      (circuit == Circuit.triphase ? 0 : 1);
  return ligne[colonne].toDouble();
}
