/// Réglage magnétique des disjoncteurs : multiple de Ir au déclenchement.
library;

enum CourbeDisjoncteur {
  b('B ou L', 5),
  c('C ou U', 10),
  d('D', 20),
  k('K', 14),
  ma('MA', 12),
  z('Z', 3.6);

  const CourbeDisjoncteur(this.libelle, this.multiple);
  final String libelle;

  /// Im / Ir (valeurs du classeur).
  final double multiple;
}

/// Réglage magnétique : une courbe normalisée (petits disjoncteurs) ou un
/// multiple de Ir saisi (disjoncteurs industriels). Dans ce second cas le
/// classeur applique 1,2 × le multiple saisi.
class ReglageMagnetique {
  const ReglageMagnetique.courbe(CourbeDisjoncteur this.courbe)
      : multipleSaisi = null;
  const ReglageMagnetique.multipleIr(double this.multipleSaisi) : courbe = null;

  final CourbeDisjoncteur? courbe;
  final double? multipleSaisi;

  /// Im / Ir retenu pour le calcul.
  double get multiple =>
      courbe != null ? courbe!.multiple : multipleSaisi! * 1.2;
}
