import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/coefficient_k.dart';
import '../../core/calculs/surcharges.dart';
import '../../core/donnees/types.dart';

/// Saisies de l'écran « Protection contre les surcharges ».
class SurchargeEntree {
  const SurchargeEntree({
    this.typeCable = 'U1000R2V',
    this.ame = Ame.cuivre,
    this.circuit = Circuit.triphase,
    this.mode = ModePose.c,
    this.section = 10,
    this.nbParalleles = 1,
    this.kAssiste = true,
    this.kManuel = 1,
    this.paramsK = const ParamsK(),
  });

  final String typeCable;
  final Ame ame;
  final Circuit circuit;
  final ModePose mode;
  final double section;
  final int nbParalleles;

  /// true : K calculé par l'assistant ; false : valeur [kManuel] saisie.
  final bool kAssiste;
  final double kManuel;
  final ParamsK paramsK;

  Isolant get isolant => isolantParTypeCable[typeCable]!;

  SurchargeEntree copyWith({
    String? typeCable,
    Ame? ame,
    Circuit? circuit,
    ModePose? mode,
    double? section,
    int? nbParalleles,
    bool? kAssiste,
    double? kManuel,
    ParamsK? paramsK,
  }) =>
      SurchargeEntree(
        typeCable: typeCable ?? this.typeCable,
        ame: ame ?? this.ame,
        circuit: circuit ?? this.circuit,
        mode: mode ?? this.mode,
        section: section ?? this.section,
        nbParalleles: nbParalleles ?? this.nbParalleles,
        kAssiste: kAssiste ?? this.kAssiste,
        kManuel: kManuel ?? this.kManuel,
        paramsK: paramsK ?? this.paramsK,
      );
}

class SurchargeNotifier extends Notifier<SurchargeEntree> {
  @override
  SurchargeEntree build() => const SurchargeEntree();

  void modifier(SurchargeEntree Function(SurchargeEntree) f) =>
      state = f(state);

  void modifierK(ParamsK Function(ParamsK) f) =>
      state = state.copyWith(paramsK: f(state.paramsK));
}

final surchargeEntreeProvider =
    NotifierProvider<SurchargeNotifier, SurchargeEntree>(SurchargeNotifier.new);

/// Résultat affiché : K retenu, calcul et éventuel message d'erreur.
class SurchargeVue {
  const SurchargeVue({required this.k, this.resultat, this.erreur});

  final double k;
  final ResultatSurcharge? resultat;
  final String? erreur;
}

final surchargeVueProvider = Provider<SurchargeVue>((ref) {
  final e = ref.watch(surchargeEntreeProvider);
  try {
    final k = e.kAssiste
        ? coefficientPourMode(e.mode, e.isolant, e.paramsK)
        : e.kManuel;
    final r = calculerSurcharge(
      isolant: e.isolant,
      circuit: e.circuit,
      mode: e.mode,
      ame: e.ame,
      section: e.section,
      coefficientK: k,
      nbParalleles: e.nbParalleles,
      edition: e.paramsK.edition,
    );
    return SurchargeVue(k: k, resultat: r);
  } on ArgumentError catch (ex) {
    return SurchargeVue(k: 0, erreur: ex.message?.toString());
  }
});
