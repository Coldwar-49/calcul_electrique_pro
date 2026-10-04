/// Coefficient K par mode de pose (onglets « K pour methode B..F »).
///
/// Chaque fonction reproduit la cellule « Coefficient K pour calcul
/// surcharge » : produit des facteurs de correction.
library;

import '../donnees/coefficients_k.dart';
import '../donnees/types.dart';

/// Paramètres saisis pour calculer K, tous modes de pose confondus.
class ParamsK {
  const ParamsK({
    this.temperature = 30,
    this.nbCircuits = 1,
    this.nbCouches = 1,
    this.plafond = false,
    this.tablettePerforee = false,
    this.risqueBe3 = false,
    this.harmoniquesSup15 = false,
    this.edition = EditionNorme.normeActuelle,
    this.symetrique = true,
    this.distance = DistanceCables.nulle,
    this.k7 = 1,
  });

  final int temperature;
  final int nbCircuits;
  final int nbCouches;
  final bool plafond;
  final bool tablettePerforee;
  final bool risqueBe3;
  final bool harmoniquesSup15;

  /// Édition pour K5 : 0,86 (2024, tableau 52.20) ou 0,84 (classeur 2013).
  final EditionNorme edition;
  final bool symetrique;
  final DistanceCables distance;

  /// Coefficient complémentaire K7 (modes B et C), 1 si aucun cas particulier.
  final double k7;

  ParamsK copyWith({
    int? temperature,
    int? nbCircuits,
    int? nbCouches,
    bool? plafond,
    bool? tablettePerforee,
    bool? risqueBe3,
    bool? harmoniquesSup15,
    EditionNorme? edition,
    bool? symetrique,
    DistanceCables? distance,
    double? k7,
  }) =>
      ParamsK(
        temperature: temperature ?? this.temperature,
        nbCircuits: nbCircuits ?? this.nbCircuits,
        nbCouches: nbCouches ?? this.nbCouches,
        plafond: plafond ?? this.plafond,
        tablettePerforee: tablettePerforee ?? this.tablettePerforee,
        risqueBe3: risqueBe3 ?? this.risqueBe3,
        harmoniquesSup15: harmoniquesSup15 ?? this.harmoniquesSup15,
        edition: edition ?? this.edition,
        symetrique: symetrique ?? this.symetrique,
        distance: distance ?? this.distance,
        k7: k7 ?? this.k7,
      );
}

/// Température effective : la valeur saisie si elle existe dans le tableau
/// 52K du mode, sinon la référence (30 °C dans l'air, 20 °C dans le sol).
int temperatureEffective(ModePose mode, Isolant isolant, int saisie) {
  final sol = mode == ModePose.d;
  return temperaturesDisponibles(isolant, sol: sol).contains(saisie)
      ? saisie
      : (sol ? 20 : 30);
}

/// Coefficient K du mode de pose [mode]. Les nombres de circuits au-delà de
/// la table sont ramenés au maximum de la table.
double coefficientPourMode(ModePose mode, Isolant isolant, ParamsK p) {
  final t = temperatureEffective(mode, isolant, p.temperature);
  final n = p.nbCircuits < nombreMaxCircuits(mode)
      ? p.nbCircuits
      : nombreMaxCircuits(mode);
  return switch (mode) {
    ModePose.b => coefficientMethodeB(
        isolant: isolant,
        temperature: t,
        nbCircuits: n,
        nbCouches: p.nbCouches,
        risqueBe3: p.risqueBe3,
        harmoniquesSup15: p.harmoniquesSup15,
        edition: p.edition,
        k7: p.k7,
        symetrique: p.symetrique),
    ModePose.c => coefficientMethodeC(
        isolant: isolant,
        temperature: t,
        nbCircuits: n,
        plafond: p.plafond,
        nbCouches: p.nbCouches,
        risqueBe3: p.risqueBe3,
        harmoniquesSup15: p.harmoniquesSup15,
        edition: p.edition,
        k7: p.k7,
        symetrique: p.symetrique),
    ModePose.d => coefficientMethodeD(
        isolant: isolant,
        temperatureSol: t,
        k2: k52r(n, p.distance),
        risqueBe3: p.risqueBe3,
        harmoniquesSup15: p.harmoniquesSup15,
        edition: p.edition,
        symetrique: p.symetrique),
    ModePose.e || ModePose.f => coefficientMethodeEF(
        isolant: isolant,
        temperature: t,
        nbCircuits: n,
        tablettePerforee: p.tablettePerforee,
        nbCouches: p.nbCouches,
        risqueBe3: p.risqueBe3,
        harmoniquesSup15: p.harmoniquesSup15,
        edition: p.edition,
        symetrique: p.symetrique),
  };
}

/// Méthode B : K1 × K2 × K3 × K4 × K5 × K7 × K6 (cellule U5).
double coefficientMethodeB({
  required Isolant isolant,
  required int temperature,
  required int nbCircuits,
  required int nbCouches,
  bool risqueBe3 = false,
  bool harmoniquesSup15 = false,
  EditionNorme edition = EditionNorme.normeActuelle,
  double k7 = k7MethodeB,
  bool symetrique = true,
}) =>
    k1Temperature(isolant, temperature) *
    k2MethodeB(nbCircuits) *
    k3Couches(nbCouches) *
    kRisqueBe3(risqueBe3) *
    kHarmoniques(harmoniquesSup15, edition: edition) *
    k7 *
    kSymetrie(symetrique);

/// Méthode C : K1 × K2 × K3 × K4 × K5 × K7 × K6 (cellule T5).
double coefficientMethodeC({
  required Isolant isolant,
  required int temperature,
  required int nbCircuits,
  required bool plafond,
  required int nbCouches,
  bool risqueBe3 = false,
  bool harmoniquesSup15 = false,
  EditionNorme edition = EditionNorme.normeActuelle,
  double k7 = k7MethodeC,
  bool symetrique = true,
}) =>
    k1Temperature(isolant, temperature) *
    k2MethodeC(nbCircuits, plafond: plafond) *
    k3Couches(nbCouches) *
    kRisqueBe3(risqueBe3) *
    kHarmoniques(harmoniquesSup15, edition: edition) *
    k7 *
    kSymetrie(symetrique);

/// Méthode D : K1(sol) × K2(52R) × K3(52S) × K4(52T) × K5 × K6 × K7 × K8
/// (cellule L11). K2, K3, K4 et K8 sont saisis (cellules D12, D16, D20, L9).
double coefficientMethodeD({
  required Isolant isolant,
  required int temperatureSol,
  double k2 = 1,
  double k3 = 1,
  double k4 = 1,
  bool risqueBe3 = false,
  bool harmoniquesSup15 = false,
  EditionNorme edition = EditionNorme.normeActuelle,
  bool symetrique = true,
  double k8 = 1,
}) =>
    k1Temperature(isolant, temperatureSol, sol: true) *
    k2 *
    k3 *
    k4 *
    kRisqueBe3(risqueBe3) *
    kHarmoniques(harmoniquesSup15, edition: edition) *
    kSymetrie(symetrique) *
    k8;

/// Méthodes E et F : K1 × K2 × K3 × K4 × K5 × K6 (cellules M5).
/// E = câbles multipolaires, F = câbles unipolaires (mêmes tables).
double coefficientMethodeEF({
  required Isolant isolant,
  required int temperature,
  required int nbCircuits,
  required bool tablettePerforee,
  required int nbCouches,
  bool risqueBe3 = false,
  bool harmoniquesSup15 = false,
  EditionNorme edition = EditionNorme.normeActuelle,
  bool symetrique = true,
}) =>
    k1Temperature(isolant, temperature) *
    k2MethodesEF(nbCircuits, tablettePerforee: tablettePerforee) *
    k3Couches(nbCouches) *
    kRisqueBe3(risqueBe3) *
    kHarmoniques(harmoniquesSup15, edition: edition) *
    kSymetrie(symetrique);
