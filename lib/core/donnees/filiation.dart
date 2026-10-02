/// Modèle des tableaux de filiation (pouvoir de coupure renforcé).
library;

/// Un tableau de filiation : appareils amont en colonnes, appareils aval en
/// lignes, pouvoir de coupure renforcé (kA) à leur croisement.
class TableFiliation {
  const TableFiliation({
    required this.numero,
    required this.catalogue,
    required this.tension,
    required this.libelle,
    required this.amonts,
    required this.pdcAmont,
    required this.avals,
    required this.valeurs,
  });

  /// Numéro de la feuille du classeur d'origine.
  final int numero;

  /// Année du catalogue constructeur, par exemple « 2005 » ou « 1998/1999 ».
  final String catalogue;

  /// Tension du réseau en volts (230, 400 ou 440).
  final int tension;

  /// Familles d'appareils, par exemple « Amont Multi 9 / Aval Multi 9 ».
  final String libelle;

  final List<String> amonts;

  /// Pouvoir de coupure propre de chaque appareil amont (kA), `null` si le
  /// tableau ne l'indique pas.
  final List<double?> pdcAmont;

  final List<String> avals;

  /// `valeurs[ligne aval][colonne amont]` : Pdc renforcé en kA, `null` si
  /// aucune filiation n'est prévue.
  final List<List<double?>> valeurs;

  /// Pouvoir de coupure renforcé de [aval] protégé par [amont], ou `null`.
  double? renforce(String amont, String aval) {
    final c = amonts.indexOf(amont);
    final l = avals.indexOf(aval);
    if (c < 0 || l < 0) return null;
    return valeurs[l][c];
  }

  /// Pouvoir de coupure propre de [amont] (kA), ou `null`.
  double? pdcDe(String amont) {
    final c = amonts.indexOf(amont);
    return c < 0 ? null : pdcAmont[c];
  }
}
