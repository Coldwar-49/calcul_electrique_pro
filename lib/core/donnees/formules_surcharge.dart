/// Formules empiriques de l'onglet Surcharges : I = a × S^b (colonnes T:AH).
library;

import 'types.dart';

/// Coefficients (a, b) pour une âme cuivre et une âme aluminium.
typedef CoeffsAme = ({double aCu, double bCu, double aAl, double bAl});

class LigneSurcharge {
  const LigneSurcharge({
    required this.isolant,
    required this.circuit,
    required this.mode,
    required this.petite,
    this.grande,
    this.petiteTouteSection = false,
  });

  final Isolant isolant;
  final Circuit circuit;
  final ModePose mode;

  /// Formule du bloc S < 25 mm² (colonnes U/V), appliquée si S <= 16.
  final CoeffsAme petite;

  /// Formule du bloc S >= 25 mm² (colonnes AC/AD), appliquée si S >= 25.
  final CoeffsAme? grande;

  /// Lignes sans condition de section dans le classeur (PVC 3 B, PR 2 F).
  final bool petiteTouteSection;

  /// Coefficients applicables pour [section] (après correctif 50 -> 47,5),
  /// ou `null` si aucune colonne du classeur ne s'applique.
  CoeffsAme? pour(double section) {
    if (petiteTouteSection) return petite;
    if (section <= 16) return petite;
    if (section >= 25) return grande;
    return null;
  }
}

CoeffsAme _c(double aCu, double bCu, double aAl, double bAl) =>
    (aCu: aCu, bCu: bCu, aAl: aAl, bAl: bAl);

const _pvc = Isolant.pvc;
const _pr = Isolant.pr;
const _m = Circuit.monophase;
const _t = Circuit.triphase;

final List<LigneSurcharge> lignesSurcharge = [
  LigneSurcharge(
      isolant: _pvc, circuit: _t, mode: ModePose.b,
      petite: _c(11.84, 0.628, 9.265, 0.627), petiteTouteSection: true),
  LigneSurcharge(
      isolant: _pvc, circuit: _m, mode: ModePose.b,
      petite: _c(13.5, 0.625, 10.5, 0.625),
      grande: _c(12.4, 0.635, 9.536, 0.624)),
  LigneSurcharge(
      isolant: _pvc, circuit: _t, mode: ModePose.c,
      petite: _c(13.5, 0.625, 10.5, 0.625),
      grande: _c(12.4, 0.635, 9.536, 0.624)),
  LigneSurcharge(
      isolant: _pvc, circuit: _t, mode: ModePose.e,
      petite: _c(14.3, 0.62, 11, 0.62), grande: _c(12.9, 0.64, 9.9, 0.64)),
  LigneSurcharge(
      isolant: _pr, circuit: _t, mode: ModePose.b,
      petite: _c(15, 0.625, 11.6, 0.625), grande: _c(15, 0.625, 10.55, 0.64)),
  LigneSurcharge(
      isolant: _pvc, circuit: _m, mode: ModePose.c,
      petite: _c(15, 0.625, 11.6, 0.625), grande: _c(15, 0.625, 10.55, 0.64)),
  LigneSurcharge(
      isolant: _pvc, circuit: _t, mode: ModePose.f,
      petite: _c(15, 0.625, 11.6, 0.625), grande: _c(15, 0.625, 10.55, 0.64)),
  LigneSurcharge(
      isolant: _pr, circuit: _t, mode: ModePose.c,
      petite: _c(16.8, 0.62, 12.8, 0.627),
      grande: _c(15.4, 0.635, 11.5, 0.639)),
  LigneSurcharge(
      isolant: _pvc, circuit: _m, mode: ModePose.e,
      petite: _c(16.8, 0.62, 12.8, 0.627),
      grande: _c(15.4, 0.635, 11.5, 0.639)),
  LigneSurcharge(
      isolant: _pr, circuit: _m, mode: ModePose.b,
      petite: _c(17.8, 0.623, 13.7, 0.623),
      grande: _c(16.4, 0.637, 12.6, 0.635)),
  LigneSurcharge(
      isolant: _pr, circuit: _t, mode: ModePose.e,
      petite: _c(17.8, 0.623, 13.7, 0.623),
      grande: _c(16.4, 0.637, 12.6, 0.635)),
  LigneSurcharge(
      isolant: _pvc, circuit: _m, mode: ModePose.f,
      petite: _c(17.8, 0.623, 13.7, 0.623),
      grande: _c(16.4, 0.637, 12.6, 0.635)),
  LigneSurcharge(
      isolant: _pr, circuit: _m, mode: ModePose.c,
      petite: _c(18.77, 0.628, 14.8, 0.625),
      grande: _c(17, 0.65, 12.6, 0.648)),
  LigneSurcharge(
      isolant: _pr, circuit: _t, mode: ModePose.f,
      petite: _c(18.77, 0.628, 14.8, 0.625),
      grande: _c(17, 0.65, 12.6, 0.648)),
  LigneSurcharge(
      isolant: _pr, circuit: _m, mode: ModePose.e,
      petite: _c(20.5, 0.623, 16, 0.625),
      grande: _c(18.6, 0.646, 13.4, 0.649)),
  LigneSurcharge(
      isolant: _pr, circuit: _m, mode: ModePose.f,
      petite: _c(20.8, 0.636, 14.7, 0.654), petiteTouteSection: true),
  LigneSurcharge(
      isolant: _pvc, circuit: _t, mode: ModePose.d,
      petite: _c(20.86, 0.55, 16.14, 0.55),
      grande: _c(20.86, 0.55, 16.14, 0.55)),
  LigneSurcharge(
      isolant: _pvc, circuit: _m, mode: ModePose.d,
      petite: _c(25.14, 0.551, 19.285, 0.551),
      grande: _c(25.14, 0.551, 19.285, 0.551)),
  LigneSurcharge(
      isolant: _pr, circuit: _t, mode: ModePose.d,
      petite: _c(24.71, 0.549, 19, 0.551), grande: _c(24.71, 0.549, 19, 0.551)),
  LigneSurcharge(
      isolant: _pr, circuit: _m, mode: ModePose.d,
      petite: _c(29.71, 0.548, 22.57, 0.55),
      grande: _c(29.71, 0.548, 22.57, 0.55)),
];

/// Ligne du classeur pour (isolant, circuit, mode), ou `null`.
LigneSurcharge? ligneSurcharge(Isolant isolant, Circuit circuit, ModePose mode) {
  for (final l in lignesSurcharge) {
    if (l.isolant == isolant && l.circuit == circuit && l.mode == mode) {
      return l;
    }
  }
  return null;
}
