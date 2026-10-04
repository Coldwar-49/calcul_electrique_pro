/// Protection contre les surcharges (onglet « Surcharges » du classeur).
library;

import 'dart:math' as math;

import '../donnees/calibres.dart';
import '../donnees/courants_admissibles_2024.dart';
import '../donnees/courants_admissibles_d1.dart';
import '../donnees/courants_admissibles_d2.dart';
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
  EditionNorme edition = EditionNorme.normeActuelle,
  bool enConduit = false,
}) {
  // 2024, mode D : câbles directement enterrés, tableau 52.8H.2 (sol à
  // 2,5 K·m/W ; la résistivité réelle est corrigée par K).
  if (edition != EditionNorme.norme2013 && mode == ModePose.d) {
    return enConduit
        ? courantD1(ame, isolant, circuit, section)
        : courantD2(ame, isolant, circuit, section);
  }
  // 2024, modes B, C, E, F : tableaux 52.8C, 52.8E, 52.8F (valeurs exactes ;
  // une case vide du tableau donne « ! »).
  if (edition != EditionNorme.norme2013) {
    return courantTableau2024(mode, ame, isolant, circuit, section);
  }
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
  EditionNorme edition = EditionNorme.normeActuelle,
  bool enConduit = false,
}) {
  final base = courantFormule(
        isolant: isolant,
        circuit: circuit,
        mode: mode,
        ame: ame,
        section: section,
        edition: edition,
        enConduit: enConduit,
      ) ??
      0;
  final i = coefficientK * nbParalleles * base * 1.05;
  return ResultatSurcharge(
    i: i,
    calibre: i == 0 ? null : calibrePourCourant(i),
    courantBase: base,
  );
}
