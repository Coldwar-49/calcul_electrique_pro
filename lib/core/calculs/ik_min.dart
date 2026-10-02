/// Courant de défaut minimal If (Ik min) et vérification de la protection
/// contre les contacts indirects par la méthode des impédances.
///
/// Reprend les onglets « Ik min CI » (source transformateur) et
/// « Ik min CI GE » (source groupe électrogène). Courants en kA.
library;

import 'dart:math' as math;

import '../donnees/courbes_disjoncteurs.dart';
import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';
import 'ik_max.dart' show Couplage;

/// Le classeur utilise 1,732 pour √3.
const double _racine3 = 1.732;

enum RegimeNeutre {
  tn('TN', 1),
  itan('IT – ITAN', 0.5),
  itsn('IT – ITSN', 0.8660254038);

  const RegimeNeutre(this.libelle, this.facteur);
  final String libelle;

  /// Facteur appliqué à If selon le régime de neutre.
  final double facteur;
}

/// Impédance équivalente de la source, vue des conducteurs.
class ImpedanceSource {
  const ImpedanceSource({
    required this.u0,
    required this.r,
    required this.x,
    required this.nbSources,
  });

  /// Tension entre phases (V).
  final double u0;

  /// Résistance et réactance de la source (Ω).
  final double r;
  final double x;

  /// Transformateurs ou groupes en parallèle : la première liaison est
  /// divisée par ce nombre, comme dans le classeur.
  final int nbSources;
}

/// Source transformateur : réseau amont + transformateur (Z9, AA9, AC9, AD9).
ImpedanceSource sourceTransformateur({
  required double u0,
  required double pccMva,
  required Couplage couplage,
  required double puissanceKva,
  required double uccPourcent,
  int nbTransfos = 1,
}) {
  final zq = math.pow(1.05 * u0, 2) / (pccMva * 1000000);
  final xq = 0.995 * zq;
  final rq = 0.1 * xq;
  final zt = (1.05 * u0) * (1.05 * u0) * uccPourcent / (puissanceKva * 100000);
  return ImpedanceSource(
    u0: u0,
    x: xq + 0.95 * zt * couplage.facteurXt / nbTransfos,
    r: rq + 0.31 * zt * couplage.facteurRt / nbTransfos,
    nbSources: nbTransfos,
  );
}

/// Source groupe électrogène : réactance Xs = (2·X'd + X0) / 3 (W8, X8, Y8).
ImpedanceSource sourceGroupe({
  required double u0,
  required double puissanceKva,
  required double xdPourcent,
  required double x0Pourcent,
  int nbGroupes = 1,
}) {
  final xd = ((u0 * u0 * xdPourcent) / (puissanceKva * 100)) * 0.001;
  final x0 = ((u0 * u0 * x0Pourcent) / (puissanceKva * 100)) * 0.001;
  return ImpedanceSource(
    u0: u0,
    x: (1 / nbGroupes) * ((2 * xd) + x0) / 3,
    r: 0,
    nbSources: nbGroupes,
  );
}

/// Dispositif de protection d'une liaison (réglage magnétique et Ir).
class ProtectionIk {
  const ProtectionIk({required this.reglage, required this.ir});

  final ReglageMagnetique reglage;
  final double ir;

  /// Courant de déclenchement magnétique en ampères.
  double get im => reglage.multiple * ir;
}

class LiaisonIkMin {
  const LiaisonIkMin({
    this.ame = Ame.cuivre,
    this.longueur = 10,
    this.sectionPhase = 10,
    this.nbPhasesParPole = 1,
    this.sectionPe = 10,
    this.nbPeParPole = 1,
    this.protection,
  });

  final Ame ame;
  final double longueur;
  final double sectionPhase;
  final int nbPhasesParPole;
  final double sectionPe;
  final int nbPeParPole;

  /// Protection de la liaison ; `null` si l'onglet n'en prévoit pas.
  final ProtectionIk? protection;
}

enum StatutProtection { nonApplicable, assuree, nonAssuree }

class ResultatIkMinPoint {
  const ResultatIkMinPoint({
    required this.ifKa,
    required this.z,
    required this.statut,
    this.protecteur,
  });

  /// If (Ik min) en kA, après le facteur du régime de neutre.
  final double ifKa;

  /// Impédance de boucle cumulée (Ω).
  final double z;
  final StatutProtection statut;

  /// Indice de la liaison dont la protection assure la protection.
  final int? protecteur;
}

/// If = 0,95 × 1,05 × U / (√3 × Z), puis facteur du régime de neutre.
/// La protection est « assurée » si 1000 × If >= Im d'une protection de la
/// liaison ou d'une liaison amont (la plus proche en premier).
List<ResultatIkMinPoint> calculerIkMin(
  ImpedanceSource source,
  RegimeNeutre regime,
  List<LiaisonIkMin> liaisons,
) {
  final resultats = <ResultatIkMinPoint>[];
  var r = source.r;
  var x = source.x;
  for (var k = 0; k < liaisons.length; k++) {
    final l = liaisons[k];
    final rho = rhoChuteTension(l.ame);
    final sp = corrigerSection(l.sectionPhase);
    final spe = corrigerSection(l.sectionPe);

    var dR = rho *
        l.longueur *
        ((1 / (sp * l.nbPhasesParPole)) + (1 / (spe * l.nbPeParPole)));
    var dX = reactanceLineique *
        l.longueur *
        ((1 / l.nbPhasesParPole) + (1 / l.nbPeParPole));
    if (k == 0) {
      dR /= source.nbSources;
      dX /= source.nbSources;
    }
    r += dR;
    x += dX;

    final z = math.sqrt(r * r + x * x);
    final ifKa = (0.95 * 1.05 * source.u0 / _racine3) / (z * 1000) *
        regime.facteur;

    var statut = StatutProtection.nonApplicable;
    int? protecteur;
    for (var j = k; j >= 0; j--) {
      final p = liaisons[j].protection;
      if (p == null) continue;
      statut = StatutProtection.nonAssuree;
      if (1000 * ifKa >= p.im) {
        statut = StatutProtection.assuree;
        protecteur = j;
        break;
      }
    }
    resultats.add(ResultatIkMinPoint(
      ifKa: ifKa,
      z: z,
      statut: statut,
      protecteur: protecteur,
    ));
  }
  return resultats;
}
