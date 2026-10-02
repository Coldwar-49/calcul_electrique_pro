/// Tables des coefficients K (onglets « K pour methode B..F »).
///
/// Valeurs du classeur CLAUREG V3.6 (NF C 15-100, tableaux 52K, 52N, 52O,
/// 52R, 52S, 52T). Voir docs/changements_nfc15100.md pour l'état de la mise
/// à jour vers l'édition en vigueur.
library;

import 'types.dart';

// ---------------------------------------------------------------- 52K : K1

/// Isolant pour le tableau 52K : PVC ou PR/EPR.
const Map<int, double> _k1AirPvc = {
  10: 1.22, 15: 1.17, 20: 1.12, 25: 1.06, 30: 1, 35: 0.94, 40: 0.87,
  45: 0.79, 50: 0.71, 55: 0.61,
};
const Map<int, double> _k1AirPr = {
  10: 1.15, 15: 1.12, 20: 1.08, 25: 1.04, 30: 1, 35: 0.96, 40: 0.91,
  45: 0.87, 50: 0.82, 55: 0.76, 60: 0.71, 65: 0.65, 70: 0.58, 75: 0.5,
  80: 0.41,
};
const Map<int, double> _k1SolPvc = {
  10: 1.1, 15: 1.05, 20: 1, 25: 0.95, 30: 0.89, 35: 0.84, 40: 0.77,
  45: 0.71, 50: 0.63, 55: 0.55,
};
const Map<int, double> _k1SolPr = {
  10: 1.07, 15: 1.04, 20: 1, 25: 0.96, 30: 0.93, 35: 0.89, 40: 0.85,
  45: 0.8, 50: 0.76, 55: 0.71, 60: 0.65, 65: 0.6, 70: 0.53, 75: 0.46,
  80: 0.38,
};

/// K1 (température). [sol] = true pour la méthode D (température du sol).
/// Le classeur n'accepte que les multiples de 5 °C ; PVC >= 60 °C vaut 0,5
/// (air) ou 0,45 (sol). Lève [ArgumentError] hors table.
double k1Temperature(Isolant isolant, int tempC, {bool sol = false}) {
  final table = sol
      ? (isolant == Isolant.pvc ? _k1SolPvc : _k1SolPr)
      : (isolant == Isolant.pvc ? _k1AirPvc : _k1AirPr);
  if (isolant == Isolant.pvc && tempC >= 60) return sol ? 0.45 : 0.5;
  final k = table[tempC];
  if (k == null) {
    throw ArgumentError('Température $tempC °C hors tableau 52K');
  }
  return k;
}

/// Températures proposées par le tableau 52K (PVC : « 60 °C et plus »).
List<int> temperaturesDisponibles(Isolant isolant, {bool sol = false}) {
  final table = sol
      ? (isolant == Isolant.pvc ? _k1SolPvc : _k1SolPr)
      : (isolant == Isolant.pvc ? _k1AirPvc : _k1AirPr);
  final liste = table.keys.toList()..sort();
  if (isolant == Isolant.pvc) liste.add(60);
  return liste;
}

/// Nombre maximal de circuits géré par la table K2 de chaque mode de pose.
int nombreMaxCircuits(ModePose mode) => switch (mode) {
      ModePose.b => 13,
      ModePose.c => 9,
      ModePose.d => 6,
      ModePose.e || ModePose.f => 8,
    };

// ---------------------------------------------------------------- 52N : K2

/// K2 méthode B (conduits) : nombre de circuits ou câbles multiconducteurs.
double k2MethodeB(int nombre) {
  if (nombre < 1) throw ArgumentError('Nombre >= 1 requis');
  if (nombre <= 5) return const [1.0, 0.8, 0.7, 0.65, 0.6][nombre - 1];
  if (nombre <= 7) return 0.55;
  if (nombre <= 9) return 0.5;
  if (nombre <= 12) return 0.45;
  return 0.4;
}

/// K2 méthode C : murs/planchers/tablettes ou plafond.
double k2MethodeC(int nombre, {required bool plafond}) {
  if (nombre < 1) throw ArgumentError('Nombre >= 1 requis');
  const mur = [1, 0.85, 0.79, 0.75, 0.73, 0.72, 0.72, 0.71];
  const plaf = [1, 0.85, 0.76, 0.72, 0.69, 0.67, 0.66, 0.65];
  if (nombre >= 9) return plafond ? 0.64 : 0.7;
  return (plafond ? plaf : mur)[nombre - 1].toDouble();
}

/// K2 méthodes E et F : échelles/corbeaux/treillis ou tablettes perforées.
double k2MethodesEF(int nombre, {required bool tablettePerforee}) {
  if (nombre < 1) throw ArgumentError('Nombre >= 1 requis');
  const echelles = [1, 0.88, 0.82, 0.8, 0.8, 0.79, 0.79];
  const perforees = [1, 0.88, 0.82, 0.77, 0.75, 0.73, 0.73];
  if (nombre >= 8) return tablettePerforee ? 0.72 : 0.78;
  return (tablettePerforee ? perforees : echelles)[nombre - 1].toDouble();
}

// ---------------------------------------------------------------- 52O : K3

/// K3 : nombre de couches.
double k3Couches(int nombre) {
  if (nombre < 1) throw ArgumentError('Nombre >= 1 requis');
  if (nombre <= 3) return const [1.0, 0.8, 0.73][nombre - 1];
  if (nombre <= 5) return 0.7;
  if (nombre <= 8) return 0.68;
  return 0.66;
}

// ------------------------------------------------- autres facteurs (B..F)

/// Risque BE3.
double kRisqueBe3(bool oui) => oui ? 0.85 : 1;

/// Taux d'harmoniques de rang 3 > 15 %.
double kHarmoniques(bool oui) => oui ? 0.84 : 1;

/// Symétrie.
double kSymetrie(bool symetrique) => symetrique ? 1 : 0.8;

/// Coefficients complémentaires K7 de la méthode B (cellules Q7..Q25).
const double k7MethodeB = 0.9;

/// K7 de la méthode C : câbles fixés au plafond 0,95 ; sur isolateurs 1,21.
const double k7MethodeC = 0.95;
const double k7MethodeCIsolateurs = 1.21;

// ------------------------------------------------- méthode D : 52R/52S/52T

/// Distance entre câbles ou conduits (tableaux 52R et 52S).
enum DistanceCables { nulle, undiametre, cm25, cm50, m1 }

/// Tableau 52R (câbles directement posés dans le sol), nombre 2..6.
/// Colonnes : nulle, un diamètre, 25 cm, 50 cm, 1 m.
const Map<int, List<double>> _t52r = {
  2: [0.76, 0.79, 0.84, 0.88, 0.92],
  3: [0.64, 0.67, 0.74, 0.79, 0.85],
  4: [0.57, 0.61, 0.69, 0.75, 0.82],
  5: [0.52, 0.56, 0.65, 0.71, 0.80],
  6: [0.49, 0.53, 0.60, 0.69, 0.78],
};

/// Tableau 52S (groupement de conduits), nombre 2..6.
/// Colonnes : nulle, 25 cm, 50 cm, 1 m.
const Map<int, List<double>> _t52s = {
  2: [0.87, 0.93, 0.95, 0.97],
  3: [0.77, 0.87, 0.91, 0.95],
  4: [0.72, 0.84, 0.89, 0.94],
  5: [0.68, 0.81, 0.87, 0.93],
  6: [0.65, 0.79, 0.86, 0.93],
};

/// K2 de la méthode D (52R). Nombre 1 = 1.
double k52r(int nombre, DistanceCables distance) {
  if (nombre == 1) return 1;
  final ligne = _t52r[nombre];
  if (ligne == null) throw ArgumentError('Nombre $nombre hors tableau 52R');
  return ligne[distance.index];
}

/// K3 de la méthode D (52S). La distance « un diamètre » n'existe pas.
double k52s(int nombre, DistanceCables distance) {
  if (nombre == 1) return 1;
  if (distance == DistanceCables.undiametre) {
    throw ArgumentError('Distance « un diamètre » absente du tableau 52S');
  }
  final ligne = _t52s[nombre];
  if (ligne == null) throw ArgumentError('Nombre $nombre hors tableau 52S');
  final col = distance.index - (distance.index > 1 ? 1 : 0);
  return ligne[col];
}

/// Tableau 52T (plusieurs circuits dans un même conduit enterré).
const Map<int, double> _t52t = {
  1: 1, 2: 0.71, 3: 0.58, 4: 0.5, 5: 0.45, 6: 0.41, 7: 0.38, 8: 0.35,
  9: 0.33, 12: 0.29, 16: 0.25, 20: 0.22,
};

/// K4 de la méthode D (52T). Lève [ArgumentError] hors nombres du tableau.
double k52t(int nombre) {
  final k = _t52t[nombre];
  if (k == null) throw ArgumentError('Nombre $nombre hors tableau 52T');
  return k;
}

/// K8 de la méthode D : câbles dans conduits, fourreaux ou profilés enterrés.
/// Dans le classeur, L6 = 0,8 (non symétrique) / 1, et L9 (valeur saisie) = 1.
double k8MethodeD(bool symetrique) => symetrique ? 1 : 0.8;
