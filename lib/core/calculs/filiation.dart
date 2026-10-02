/// Filiation : pouvoir de coupure renforcé d'un disjoncteur aval protégé par un
/// disjoncteur amont, d'après les tableaux Merlin Gerin / Schneider.
library;

import '../donnees/filiation.dart';
import '../donnees/filiation_merlin_gerin.dart';

/// Catalogues disponibles, dans l'ordre chronologique des tableaux.
List<String> cataloguesFiliation() {
  final vus = <String>[];
  for (final t in tablesFiliationMerlinGerin) {
    if (!vus.contains(t.catalogue)) vus.add(t.catalogue);
  }
  return vus;
}

/// Tensions de réseau disponibles pour un catalogue (ordre croissant).
List<int> tensionsFiliation(String catalogue) {
  final tensions = {
    for (final t in tablesFiliationMerlinGerin)
      if (t.catalogue == catalogue) t.tension,
  }.toList()
    ..sort();
  return tensions;
}

/// Tableaux d'un catalogue et d'une tension, dans l'ordre du classeur.
List<TableFiliation> tablesFiliation(String catalogue, int tension) => [
      for (final t in tablesFiliationMerlinGerin)
        if (t.catalogue == catalogue && t.tension == tension) t,
    ];

enum StatutFiliation {
  /// Pouvoir de coupure renforcé et pouvoir de coupure amont couvrent Ik.
  assuree,

  /// Une filiation existe mais ne couvre pas Ik.
  insuffisante,

  /// Le tableau ne prévoit aucune filiation entre ces deux appareils.
  aucune,
}

class ResultatFiliation {
  const ResultatFiliation({
    required this.pdcAmont,
    required this.pdcRenforce,
    required this.statut,
  });

  /// Pouvoir de coupure propre de l'appareil amont (kA), `null` si le tableau
  /// ne l'indique pas.
  final double? pdcAmont;

  /// Pouvoir de coupure renforcé de l'aval (kA), `null` sans filiation.
  final double? pdcRenforce;
  final StatutFiliation statut;
}

/// La filiation est assurée si le pouvoir de coupure renforcé est au moins égal
/// à [ikKa] et, quand il est connu, si le pouvoir de coupure de l'amont l'est
/// aussi (13 cellules du classeur dépassent le Pdc de leur amont : la lecture
/// prudente est retenue).
ResultatFiliation verifierFiliation(
  TableFiliation table,
  String amont,
  String aval,
  double ikKa,
) {
  final renforce = table.renforce(amont, aval);
  final pdcAmont = table.pdcDe(amont);
  final StatutFiliation statut;
  if (renforce == null) {
    statut = StatutFiliation.aucune;
  } else if (renforce >= ikKa && (pdcAmont == null || pdcAmont >= ikKa)) {
    statut = StatutFiliation.assuree;
  } else {
    statut = StatutFiliation.insuffisante;
  }
  return ResultatFiliation(
    pdcAmont: pdcAmont,
    pdcRenforce: renforce,
    statut: statut,
  );
}

/// Appareil amont possible pour un aval donné.
class AmontPossible {
  const AmontPossible({
    required this.amont,
    required this.pdcAmont,
    required this.pdcRenforce,
    required this.statut,
  });

  final String amont;
  final double? pdcAmont;
  final double pdcRenforce;
  final StatutFiliation statut;
}

/// Tous les amonts du tableau qui offrent une filiation pour [aval], avec la
/// conclusion pour [ikKa].
List<AmontPossible> amontsPourAval(
  TableFiliation table,
  String aval,
  double ikKa,
) {
  final resultats = <AmontPossible>[];
  for (final amont in table.amonts) {
    final r = verifierFiliation(table, amont, aval, ikKa);
    if (r.pdcRenforce == null) continue;
    resultats.add(AmontPossible(
      amont: amont,
      pdcAmont: r.pdcAmont,
      pdcRenforce: r.pdcRenforce!,
      statut: r.statut,
    ));
  }
  return resultats;
}
