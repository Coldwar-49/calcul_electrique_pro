/// Protection contre les surcharges (onglet « Surcharges » du classeur).
library;

import 'dart:math' as math;

import '../donnees/calibres.dart';
import '../donnees/formules_surcharge.dart';
import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

/// I = a × S^b pour la ligne du classeur (colonnes U/V ou AC/AD), sans le
/// coefficient K ni le facteur 1,05. `null` si aucune colonne ne s'applique.
double? courantFormule({
  required Isolant isolant,
  required Circuit circuit,
  required ModePose mode,
  required Ame ame,
  required double section,
}) {
  final s = corrigerSection(section);
  final coeffs = ligneSurcharge(isolant, circuit, mode)?.pour(s);
  if (coeffs == null) return null;
  return ame == Ame.cuivre
      ? coeffs.aCu * math.pow(s, coeffs.bCu)
      : coeffs.aAl * math.pow(s, coeffs.bAl);
}

class ResultatSurcharge {
  const ResultatSurcharge({
    required this.i,
    required this.calibre,
    this.courantBase = 0,
  });

  /// Cellule K6 : M × L × I(formule) × 1,05.
  final double i;

  /// I(formule) = a × S^b, avant K, nombre de câbles et facteur 1,05.
  final double courantBase;

  /// Calibre normalisé In, ou `null` ("!" dans le classeur).
  final double? calibre;
}

/// K6 = M × L × (formule) × 1,05, puis calibre In.
///
/// [coefficientK] = M (produit des K1..K7, voir coefficient_k.dart).
/// [nbParalleles] = L (conducteurs en parallèle par phase).
ResultatSurcharge calculerSurcharge({
  required Isolant isolant,
  required Circuit circuit,
  required ModePose mode,
  required Ame ame,
  required double section,
  required double coefficientK,
  int nbParalleles = 1,
}) {
  final base = courantFormule(
        isolant: isolant,
        circuit: circuit,
        mode: mode,
        ame: ame,
        section: section,
      ) ??
      0;
  final i = coefficientK * nbParalleles * base * 1.05;
  return ResultatSurcharge(
    i: i,
    calibre: i == 0 ? null : calibrePourCourant(i),
    courantBase: base,
  );
}
