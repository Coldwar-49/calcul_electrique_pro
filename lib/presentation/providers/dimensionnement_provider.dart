import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';
import '../../core/calculs/dimensionnement.dart';
import '../../core/donnees/types.dart';
import 'tarif_provider.dart';

class DimensionnementEntree {
  const DimensionnementEntree({
    this.ib = 32,
    this.typeCable = 'U1000R2V',
    this.ame = Ame.cuivre,
    this.circuit = Circuit.triphase,
    this.mode = ModePose.c,
    this.coefficientK = 1,
    this.nbParalleles = 1,
    this.longueur = 20,
    this.u0 = 230,
    this.cosPhi = 0.85,
    this.usage = UsageCircuit.force,
  });

  final double ib;
  final String typeCable;
  final Ame ame;
  final Circuit circuit;
  final ModePose mode;

  /// M : produit des K1..K7, calculé par l'assistant de l'écran Surcharges.
  final double coefficientK;
  final int nbParalleles;
  final double longueur;
  final double u0;
  final double cosPhi;
  final UsageCircuit usage;

  Isolant get isolant => isolantParTypeCable[typeCable]!;

  DimensionnementEntree copyWith({
    double? ib,
    String? typeCable,
    Ame? ame,
    Circuit? circuit,
    ModePose? mode,
    double? coefficientK,
    int? nbParalleles,
    double? longueur,
    double? u0,
    double? cosPhi,
    UsageCircuit? usage,
  }) =>
      DimensionnementEntree(
        ib: ib ?? this.ib,
        typeCable: typeCable ?? this.typeCable,
        ame: ame ?? this.ame,
        circuit: circuit ?? this.circuit,
        mode: mode ?? this.mode,
        coefficientK: coefficientK ?? this.coefficientK,
        nbParalleles: nbParalleles ?? this.nbParalleles,
        longueur: longueur ?? this.longueur,
        u0: u0 ?? this.u0,
        cosPhi: cosPhi ?? this.cosPhi,
        usage: usage ?? this.usage,
      );
}

class DimensionnementNotifier extends Notifier<DimensionnementEntree> {
  @override
  DimensionnementEntree build() => const DimensionnementEntree();

  void modifier(DimensionnementEntree Function(DimensionnementEntree) f) =>
      state = f(state);
}

final dimensionnementEntreeProvider =
    NotifierProvider<DimensionnementNotifier, DimensionnementEntree>(
        DimensionnementNotifier.new);

final dimensionnementResultatProvider =
    Provider<ResultatDimensionnement>((ref) {
  final e = ref.watch(dimensionnementEntreeProvider);
  return dimensionnerCircuit(
    ib: e.ib,
    isolant: e.isolant,
    circuit: e.circuit,
    mode: e.mode,
    ame: e.ame,
    coefficientK: e.coefficientK,
    longueur: e.longueur,
    u0: e.u0,
    cosPhi: e.cosPhi,
    tarif: ref.watch(tarifProvider),
    usage: e.usage,
    nbParalleles: e.nbParalleles,
  );
});
