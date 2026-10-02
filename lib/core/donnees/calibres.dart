/// Choix du calibre In à partir de I (onglet Surcharges, cellules T30:X30).
library;

/// (seuil exclusif, calibre) : si I < seuil, le calibre est retenu.
const List<(double, double)> seuilsCalibres = [
  (0.655, 0), // en dessous : "!" dans le classeur
  (1.31, 0.5),
  (2.62, 1),
  (5.24, 2),
  (7.86, 4),
  (13.1, 6),
  (17.6, 10),
  (22, 16),
  (27.5, 20),
  (35.2, 25),
  (44, 32),
  (55, 40),
  (69.3, 50),
  (88, 63),
  (110, 80),
  (137.5, 100),
  (176, 125),
  (220, 160),
  (275, 200),
  (346.5, 250),
  (440, 315),
  (550, 400),
  (693, 500),
  (880, 630),
  (1100, 800),
  (1375, 1000),
];

/// Calibre pour 1375 A et plus.
const double calibreMax = 1250;

/// Calibres normalisés, du plus petit au plus grand (valeurs de la cascade).
final List<double> calibresNormalises = [
  for (final (_, c) in seuilsCalibres)
    if (c != 0) c,
  calibreMax,
];

/// Retourne le calibre normalisé, ou `null` si le classeur affiche "!".
double? calibrePourCourant(double i) {
  for (final (seuil, calibre) in seuilsCalibres) {
    if (i < seuil) return calibre == 0 ? null : calibre;
  }
  return calibreMax;
}
