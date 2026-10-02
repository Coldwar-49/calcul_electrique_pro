/// Courants de fusion Ia des fusibles gG et aM (onglet « Résistance PE
/// Fusibles », colonnes Q:W) et coefficient des circuits divisionnaires.
library;

enum TypeFusible {
  gg('gG', 1.88),
  am('aM', 1.53);

  const TypeFusible(this.libelle, this.coefficientDivisionnaire);
  final String libelle;

  /// Coefficient appliqué pour les circuits divisionnaires.
  final double coefficientDivisionnaire;
}

/// (calibre en A, Ia en A) — valeurs du classeur.
const List<(double, double)> _iaGg = [
  (10, 83.94160583941606),
  (16, 113.86138613861387),
  (20, 151.31578947368422),
  (25, 188.52459016393442),
  (32, 280.4878048780488),
  (40, 328.5714285714286),
  (50, 479.1666666666667),
  (63, 547.6190476190476),
  (80, 821.4285714285713),
  (100, 1045.4545454545455),
  (125, 1437.5),
  (160, 1642.8571428571427),
  (200, 2300),
  (250, 2948.7179487179487),
  (315, 4107.142857142857),
  (400, 5227.272727272728),
  (500, 6764.7058823529405),
  (630, 9583.333333333334),
  (800, 12777.77777777778),
  (1000, 16428.571428571428),
];

const List<(double, double)> _iaAm = [
  (10, 129.2134831460674),
  (16, 209.09090909090907),
  (20, 261.3636363636364),
  (25, 328.5714285714286),
  (32, 410.71428571428567),
  (40, 522.7272727272727),
  (50, 638.8888888888889),
  (63, 821.4285714285713),
  (80, 1045.4545454545455),
  (100, 1292.1348314606741),
  (125, 1619.7183098591552),
  (160, 2090.909090909091),
  (200, 2613.636363636364),
  (250, 3285.7142857142853),
  (315, 4107.142857142857),
  (400, 5227.272727272728),
  (500, 6388.88888888889),
  (630, 8214.285714285714),
  (800, 10454.545454545456),
  (1000, 12777.77777777778),
];

List<(double, double)> _table(TypeFusible t) =>
    t == TypeFusible.gg ? _iaGg : _iaAm;

/// Calibres proposés pour un type de fusible.
List<double> calibresFusible(TypeFusible t) =>
    [for (final (c, _) in _table(t)) c];

/// Ia pour un calibre, comme la fonction RECHERCHE du classeur : la dernière
/// ligne dont le calibre est <= [calibre]. Lève [ArgumentError] sous 10 A.
double courantIa(TypeFusible type, double calibre) {
  double? ia;
  for (final (c, valeur) in _table(type)) {
    if (c <= calibre) ia = valeur;
  }
  if (ia == null) {
    throw ArgumentError('Calibre $calibre A absent de la table ${type.libelle}');
  }
  return ia;
}
