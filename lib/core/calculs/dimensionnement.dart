/// Assistant de dimensionnement : plus petite section qui satisfait à la fois
/// la protection contre les surcharges (onglet « Surcharges ») et la chute de
/// tension (onglet « Chute de tension »). Aucune règle nouvelle : il enchaîne
/// les deux calculs existants sur la liste des sections usuelles.
library;

import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';
import 'chute_tension.dart';
import 'surcharges.dart';

class CandidatSection {
  const CandidatSection({
    required this.section,
    required this.iz,
    required this.calibre,
    required this.surchargeOk,
    required this.chute,
  });

  final double section;

  /// Courant admissible calculé par l'onglet Surcharges (cellule K6).
  final double iz;

  /// Calibre normalisé In, `null` si le classeur affiche "!".
  final double? calibre;

  /// In ≥ Ib (le calibre existe et couvre le courant d'emploi).
  final bool surchargeOk;
  final ResultatChuteTension chute;

  bool get conforme => surchargeOk && chute.conforme;
}

class ResultatDimensionnement {
  const ResultatDimensionnement({required this.candidats, this.retenu});

  /// Toutes les sections essayées, de la plus petite à la plus grande.
  final List<CandidatSection> candidats;

  /// Première section conforme, `null` si aucune section usuelle ne convient.
  final CandidatSection? retenu;
}

/// Essaie les sections usuelles par ordre croissant.
///
/// [coefficientK] = M (voir coefficient_k.dart), [nbParalleles] = L.
/// Les sections sans formule pour ce mode de pose sont ignorées.
ResultatDimensionnement dimensionnerCircuit({
  required double ib,
  required Isolant isolant,
  required Circuit circuit,
  required ModePose mode,
  required Ame ame,
  required double coefficientK,
  required double longueur,
  required double u0,
  required double cosPhi,
  required Tarif tarif,
  required UsageCircuit usage,
  int nbParalleles = 1,
}) {
  final schema = circuit == Circuit.monophase
      ? SchemaCircuit.monophase
      : SchemaCircuit.triphaseEquilibre;
  final candidats = <CandidatSection>[];
  for (final s in sectionsUsuelles) {
    final r = calculerSurcharge(
      isolant: isolant,
      circuit: circuit,
      mode: mode,
      ame: ame,
      section: s,
      coefficientK: coefficientK,
      nbParalleles: nbParalleles,
    );
    if (r.courantBase == 0) continue;
    final chute = calculerChuteTension([
      LigneChuteTension(
        circuit: schema,
        u0: u0,
        section: s,
        nbConducteursParPole: nbParalleles,
        longueur: longueur,
        ame: ame,
        cosPhi: cosPhi,
        ib: ib,
        tarif: tarif,
        usage: usage,
      ),
    ]).single;
    candidats.add(CandidatSection(
      section: s,
      iz: r.i,
      calibre: r.calibre,
      surchargeOk: r.calibre != null && r.calibre! >= ib,
      chute: chute,
    ));
  }
  return ResultatDimensionnement(
    candidats: candidats,
    retenu: candidats.where((c) => c.conforme).firstOrNull,
  );
}
