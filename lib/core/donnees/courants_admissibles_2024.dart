/// Courants admissibles des méthodes de référence B1, C, E et F, NF C 15-100-1
/// (2024-08), tableaux 52.8C, 52.8E et 52.8F (captures fournies par
/// l'utilisateur, relues à l'écran). Cuivre et aluminium, 1,5 à 630 mm².
///
/// Colonnes : PVC 3 conducteurs chargés, PVC 2, PR 3, PR 2. Une case vide du
/// tableau (« - ») est `null`. Pour la méthode F, les circuits triphasés sont
/// ceux de câbles monoconducteurs en trèfle. Tolérance de la norme : 5 %.
library;

import 'types.dart';

// Tableau 52.8C - méthode B1
final Map<double, List<double?>> _b1Cuivre = {
  1.5: [15.5, 17.5, 20, 23],
  2.5: [21, 24, 28, 31],
  4: [28, 32, 37, 42],
  6: [36, 41, 48, 54],
  10: [50, 57, 66, 75],
  16: [68, 76, 88, 100],
  25: [89, 101, 117, 133],
  35: [110, 125, 144, 164],
  50: [134, 151, 175, 198],
  70: [171, 192, 222, 253],
  95: [207, 232, 269, 306],
  120: [239, 269, 312, 354],
  150: [262, 300, 342, 393],
  185: [296, 341, 384, 449],
  240: [346, 400, 450, 528],
  300: [394, 458, 514, 603],
  400: [null, null, null, 745],
  500: [null, null, null, 859],
  630: [null, null, null, 995],
};
final Map<double, List<double?>> _b1Aluminium = {
  10: [39, 44, 52, 59],
  16: [53, 60, 71, 79],
  25: [70, 79, 93, 105],
  35: [86, 97, 116, 130],
  50: [104, 118, 140, 157],
  70: [133, 150, 179, 200],
  95: [161, 181, 217, 242],
  120: [186, 210, 251, 281],
  150: [204, 234, 267, 307],
  185: [230, 266, 300, 351],
  240: [269, 312, 351, 412],
  300: [306, 358, 402, 471],
  400: [null, null, null, 566],
  500: [null, null, null, 652],
  630: [null, null, null, 755],
};

// Tableau 52.8E - méthode C
final Map<double, List<double?>> _cCuivre = {
  1.5: [17.5, 19.5, 22, 24],
  2.5: [24, 27, 30, 33],
  4: [32, 36, 40, 45],
  6: [41, 46, 52, 58],
  10: [57, 63, 71, 80],
  16: [76, 85, 96, 107],
  25: [96, 112, 119, 138],
  35: [119, 138, 147, 171],
  50: [144, 168, 179, 209],
  70: [184, 213, 229, 269],
  95: [223, 258, 278, 328],
  120: [259, 299, 322, 382],
  150: [299, 344, 371, 441],
  185: [341, 392, 424, 506],
  240: [403, 461, 500, 599],
  300: [464, 530, 576, 693],
  400: [null, null, 692, 835],
  500: [null, null, 797, 966],
  630: [null, null, 923, 1122],
};
final Map<double, List<double?>> _cAluminium = {
  10: [44, 49, 57, 62],
  16: [59, 66, 76, 84],
  25: [73, 83, 90, 101],
  35: [90, 103, 112, 126],
  50: [110, 125, 136, 154],
  70: [140, 160, 174, 198],
  95: [170, 195, 211, 241],
  120: [197, 226, 245, 280],
  150: [227, 261, 283, 324],
  185: [259, 298, 323, 371],
  240: [305, 352, 382, 439],
  300: [351, 406, 440, 508],
  400: [null, null, 529, 612],
  500: [null, null, 610, 707],
  630: [null, null, 707, 821],
};

// Tableau 52.8F - méthode E (câbles multiconducteurs)
final Map<double, List<double?>> _eCuivre = {
  1.5: [18.5, 22, 23, 26],
  2.5: [25, 30, 32, 36],
  4: [34, 40, 42, 49],
  6: [43, 51, 54, 63],
  10: [60, 70, 75, 86],
  16: [80, 94, 100, 115],
  25: [101, 119, 127, 149],
  35: [126, 148, 158, 185],
  50: [153, 180, 192, 225],
  70: [196, 232, 246, 289],
  95: [238, 282, 298, 352],
  120: [276, 328, 346, 410],
  150: [319, 379, 399, 473],
  185: [364, 434, 456, 542],
  240: [430, 514, 538, 641],
  300: [497, 593, 621, 741],
  400: [null, null, null, null],
  500: [null, null, null, null],
  630: [null, null, null, null],
};
final Map<double, List<double?>> _eAluminium = {
  10: [46, 54, 58, 67],
  16: [61, 73, 77, 91],
  25: [78, 89, 97, 108],
  35: [96, 111, 120, 135],
  50: [117, 135, 146, 164],
  70: [150, 173, 187, 211],
  95: [183, 210, 227, 257],
  120: [212, 244, 263, 300],
  150: [245, 282, 304, 346],
  185: [280, 322, 347, 397],
  240: [330, 380, 409, 470],
  300: [381, 439, 471, 543],
  400: [null, null, null, null],
  500: [null, null, null, null],
  630: [null, null, null, null],
};

// Tableau 52.8F - méthode F (câbles monoconducteurs : 2 conducteurs, 3 en trèfle)
final Map<double, List<double?>> _fCuivre = {
  1.5: [19.5, 23, 24, null],
  2.5: [27, 31, 33, null],
  4: [36, 42, 45, null],
  6: [46, 54, 58, null],
  10: [63, 75, 80, null],
  16: [85, 100, 107, null],
  25: [110, 131, 135, 161],
  35: [137, 162, 169, 200],
  50: [167, 196, 207, 242],
  70: [216, 251, 268, 310],
  95: [264, 304, 328, 377],
  120: [308, 352, 383, 437],
  150: [356, 406, 444, 504],
  185: [409, 463, 510, 575],
  240: [485, 546, 607, 679],
  300: [561, 629, 703, 783],
  400: [656, 754, 823, 940],
  500: [749, 868, 946, 1083],
  630: [855, 1005, 1088, 1254],
};
final Map<double, List<double?>> _fAluminium = {
  10: [49, 58, 62, null],
  16: [66, 77, 84, null],
  25: [84, 97, 103, 121],
  35: [105, 120, 129, 150],
  50: [128, 146, 159, 184],
  70: [166, 187, 206, 237],
  95: [203, 227, 253, 289],
  120: [237, 263, 296, 337],
  150: [274, 304, 343, 389],
  185: [315, 347, 395, 447],
  240: [375, 409, 471, 530],
  300: [434, 471, 547, 613],
  400: [526, 600, 663, 740],
  500: [610, 694, 770, 856],
  630: [711, 808, 899, 996],
};

/// Courant admissible (A) du tableau 2024 pour le mode [mode] (B = B1), ou
/// `null` si la case est vide (section non prévue) ou si [mode] est D (voir
/// courants_admissibles_d2.dart).
double? courantTableau2024(
  ModePose mode,
  Ame ame,
  Isolant isolant,
  Circuit circuit,
  double section,
) {
  final cu = ame == Ame.cuivre;
  final table = switch (mode) {
    ModePose.b => cu ? _b1Cuivre : _b1Aluminium,
    ModePose.c => cu ? _cCuivre : _cAluminium,
    ModePose.e => cu ? _eCuivre : _eAluminium,
    ModePose.f => cu ? _fCuivre : _fAluminium,
    ModePose.d => null,
  };
  final ligne = table?[section];
  if (ligne == null) return null;
  final colonne = (isolant == Isolant.pvc ? 0 : 2) +
      (circuit == Circuit.triphase ? 0 : 1);
  return ligne[colonne];
}
