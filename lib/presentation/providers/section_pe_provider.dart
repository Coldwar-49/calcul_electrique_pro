import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/section_pe.dart';
import '../../core/donnees/k_conducteurs_protection.dart';
import '../../core/donnees/types.dart';

class SectionPeEntree {
  const SectionPeEntree({
    this.sectionPhase = 95,
    this.amePhase = Ame.cuivre,
    this.lignePhase = 2,
    this.amePe = Ame.cuivre,
    this.situation = SituationPe.incorpore,
    this.lignePe = 2,
    this.protegeMecaniquement = true,
    this.verifierThermique = false,
    this.ikKa = 10,
    this.temps = 0.2,
  });

  final double sectionPhase;
  final Ame amePhase;

  /// Ligne du tableau 54A.4 pour l'isolant de la phase (détermine k1).
  final int lignePhase;
  final Ame amePe;
  final SituationPe situation;

  /// Ligne du tableau de la situation choisie (détermine k2).
  final int lignePe;
  final bool protegeMecaniquement;
  final bool verifierThermique;
  final double ikKa;
  final double temps;

  /// true : PE hors de la canalisation d'alimentation.
  bool get horsCanalisation => situation != SituationPe.incorpore;

  SectionPeEntree copyWith({
    double? sectionPhase,
    Ame? amePhase,
    int? lignePhase,
    Ame? amePe,
    SituationPe? situation,
    int? lignePe,
    bool? protegeMecaniquement,
    bool? verifierThermique,
    double? ikKa,
    double? temps,
  }) {
    final sit = situation ?? this.situation;
    final nbLignes = lignesK(sit).length;
    // Ligne par défaut quand on change de situation (liste différente).
    var ligne = lignePe ?? this.lignePe;
    if (situation != null && situation != this.situation && lignePe == null) {
      ligne = nbLignes > 2 ? 2 : 0;
    }
    return SectionPeEntree(
      sectionPhase: sectionPhase ?? this.sectionPhase,
      amePhase: amePhase ?? this.amePhase,
      lignePhase: lignePhase ?? this.lignePhase,
      amePe: amePe ?? this.amePe,
      situation: sit,
      lignePe: ligne.clamp(0, nbLignes - 1),
      protegeMecaniquement: protegeMecaniquement ?? this.protegeMecaniquement,
      verifierThermique: verifierThermique ?? this.verifierThermique,
      ikKa: ikKa ?? this.ikKa,
      temps: temps ?? this.temps,
    );
  }
}

class SectionPeNotifier extends Notifier<SectionPeEntree> {
  @override
  SectionPeEntree build() => const SectionPeEntree();

  void modifier(SectionPeEntree Function(SectionPeEntree) f) =>
      state = f(state);
}

final sectionPeEntreeProvider =
    NotifierProvider<SectionPeNotifier, SectionPeEntree>(SectionPeNotifier.new);

class SectionPeVue {
  const SectionPeVue({required this.resultat, this.k1});
  final ResultatSectionPe resultat;
  final double? k1;
}

final sectionPeVueProvider = Provider<SectionPeVue>((ref) {
  final e = ref.watch(sectionPeEntreeProvider);
  final metauxDifferents = e.amePhase != e.amePe;
  final k1 = metauxDifferents
      ? lignesKPhase()[e.lignePhase].k(e.amePhase, gros: e.sectionPhase > 300)
      : null;
  final lignePe = ligneK(e.situation, e.lignePe);
  final r = calculerSectionPe(
    sectionPhase: e.sectionPhase,
    amePhase: e.amePhase,
    amePe: e.amePe,
    k1: k1 ?? 1,
    k2: lignePe.k(e.amePe),
    k2Gros: lignePe.k(e.amePe, gros: true),
    horsCanalisation: e.horsCanalisation,
    protegeMecaniquement: e.protegeMecaniquement,
    ikA: e.verifierThermique ? e.ikKa * 1000 : null,
    temps: e.verifierThermique ? e.temps : null,
  );
  return SectionPeVue(resultat: r, k1: k1);
});
