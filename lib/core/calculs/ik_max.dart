/// Courants de court-circuit maximaux Ik3, Ik2, Ik1 (onglet « Icc Max »).
///
/// Impédances en Ω, courants en kA. Le classeur utilise 1,732 pour √3 :
/// la valeur est reprise telle quelle.
library;

import 'dart:math' as math;

import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

const double _racine3 = 1.732;

enum Couplage {
  dyn('Dyn'),
  yyn('Yyn'),
  yzn('Yzn');

  const Couplage(this.libelle);
  final String libelle;

  /// Facteur sur la résistance du transformateur en monophasé (cellule V8).
  double get facteurRt => this == Couplage.yzn ? 0.8 : 1;

  /// Facteur sur la réactance du transformateur en monophasé (cellule W8).
  double get facteurXt => switch (this) {
        Couplage.dyn => 1,
        Couplage.yyn => 4,
        Couplage.yzn => 0.8,
      };
}

/// Valeurs proposées dans l'interface (choix usuels, pas des valeurs
/// normatives : toute autre valeur reste saisissable).
const List<double> tensionsUsuelles = [230, 240, 400, 410];
const List<double> puissancesTransfoUsuelles = [
  25, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000,
  1250, 1600, 2000, 2500,
];
const List<double> uccUsuelles = [4, 6];

class ReseauAmont {
  const ReseauAmont({
    this.u0 = 400,
    this.pccMva = 500,
    this.transfoAvant2003 = false,
    this.couplage = Couplage.dyn,
    this.puissanceKva = 630,
    this.uccPourcent = 4,
    this.nbTransfos = 1,
  });

  /// Tension entre phases en volts.
  final double u0;

  /// Puissance de court-circuit amont en MVA.
  final double pccMva;

  /// Transformateur fabriqué avant juillet 2003 (facteur de tension 1 au
  /// lieu de 1,05).
  final bool transfoAvant2003;
  final Couplage couplage;
  final double puissanceKva;
  final double uccPourcent;
  final int nbTransfos;

  ReseauAmont copyWith({
    double? u0,
    double? pccMva,
    bool? transfoAvant2003,
    Couplage? couplage,
    double? puissanceKva,
    double? uccPourcent,
    int? nbTransfos,
  }) =>
      ReseauAmont(
        u0: u0 ?? this.u0,
        pccMva: pccMva ?? this.pccMva,
        transfoAvant2003: transfoAvant2003 ?? this.transfoAvant2003,
        couplage: couplage ?? this.couplage,
        puissanceKva: puissanceKva ?? this.puissanceKva,
        uccPourcent: uccPourcent ?? this.uccPourcent,
        nbTransfos: nbTransfos ?? this.nbTransfos,
      );
}

class LiaisonIkMax {
  const LiaisonIkMax({
    this.ame = Ame.cuivre,
    this.longueur = 10,
    this.sectionPhase = 25,
    this.nbPhasesParPole = 1,
    this.sectionNeutre = 25,
    this.nbNeutresParPole = 1,
  });

  final Ame ame;
  final double longueur;
  final double sectionPhase;
  final int nbPhasesParPole;
  final double sectionNeutre;
  final int nbNeutresParPole;

  LiaisonIkMax copyWith({
    Ame? ame,
    double? longueur,
    double? sectionPhase,
    int? nbPhasesParPole,
    double? sectionNeutre,
    int? nbNeutresParPole,
  }) =>
      LiaisonIkMax(
        ame: ame ?? this.ame,
        longueur: longueur ?? this.longueur,
        sectionPhase: sectionPhase ?? this.sectionPhase,
        nbPhasesParPole: nbPhasesParPole ?? this.nbPhasesParPole,
        sectionNeutre: sectionNeutre ?? this.sectionNeutre,
        nbNeutresParPole: nbNeutresParPole ?? this.nbNeutresParPole,
      );
}

/// Courants (kA) à l'arrivée d'une liaison.
class ResultatIkMaxPoint {
  const ResultatIkMaxPoint({
    required this.ik3,
    required this.ik2,
    required this.ik1,
    required this.z3,
    required this.z1,
  });

  final double ik3;
  final double ik2;
  final double ik1;

  /// Impédances cumulées en Ω (triphasé, monophasé phase-neutre).
  final double z3;
  final double z1;
}

class ResultatIkMax {
  const ResultatIkMax({required this.ik3Transfo, required this.points});

  /// Ik3 aux bornes du transformateur (cellule P8). Ne tient pas compte des
  /// transformateurs en parallèle, comme le classeur.
  final double ik3Transfo;

  /// Un point par liaison : TGBT, puis chaque tableau en aval.
  final List<ResultatIkMaxPoint> points;
}

ResultatIkMax calculerIkMax(ReseauAmont r, List<LiaisonIkMax> liaisons) {
  final facteurTension = r.transfoAvant2003 ? 1.0 : 1.05;
  final tension = 1.05 * facteurTension * r.u0 / _racine3;
  double ik(double z) => tension / (1000 * z);

  // Réseau amont (R8:T8).
  final zq = math.pow(1.05 * r.u0, 2) / (r.pccMva * 1000000);
  final xq = 0.995 * zq;
  final rq = 0.1 * xq;

  // Transformateur (R11:T11).
  final zt = (1.05 * r.u0) * (1.05 * r.u0) * r.uccPourcent /
      (r.puissanceKva * 100000);

  // Source triphasée (V11, W11) et monophasée (AB11, AC11).
  final x3Source = xq + 0.95 * zt;
  final r3Source = rq + 0.31 * zt;
  final x1Source = 0.95 * zt * r.couplage.facteurXt + xq;
  final r1Source = rq + 0.31 * zt * r.couplage.facteurRt;

  final ik3Transfo = ik(math.sqrt(x3Source * x3Source + r3Source * r3Source));

  final points = <ResultatIkMaxPoint>[];
  var r3 = 0.0, x3 = 0.0, r1 = 0.0, x1 = 0.0;
  for (var i = 0; i < liaisons.length; i++) {
    final l = liaisons[i];
    final rho = rhoIkMax(l.ame);
    final sp = corrigerSection(l.sectionPhase);
    final sn = corrigerSection(l.sectionNeutre);

    final dR3 = (rho * l.longueur) / (sp * l.nbPhasesParPole);
    final dX3 = reactanceLineique * l.longueur / l.nbPhasesParPole;
    final dR1 = rho *
        l.longueur *
        ((1 / (sp * l.nbPhasesParPole)) + (1 / (sn * l.nbNeutresParPole)));
    final dX1 = reactanceLineique *
        l.longueur *
        ((1 / l.nbPhasesParPole) + (1 / l.nbNeutresParPole));

    if (i == 0) {
      // Le classeur divise ici (source + 1re liaison) par le nombre de
      // transformateurs en parallèle.
      final n = r.nbTransfos;
      r3 = (r3Source + dR3) / n;
      x3 = (x3Source + dX3) / n;
      r1 = (r1Source + dR1) / n;
      x1 = (x1Source + dX1) / n;
    } else {
      r3 += dR3;
      x3 += dX3;
      r1 += dR1;
      x1 += dX1;
    }

    final z3 = math.sqrt(r3 * r3 + x3 * x3);
    final z1 = math.sqrt(r1 * r1 + x1 * x1);
    final ik3 = ik(z3);
    points.add(ResultatIkMaxPoint(
      ik3: ik3,
      ik2: 0.866 * ik3,
      ik1: ik(z1),
      z3: z3,
      z1: z1,
    ));
  }
  return ResultatIkMax(ik3Transfo: ik3Transfo, points: points);
}
