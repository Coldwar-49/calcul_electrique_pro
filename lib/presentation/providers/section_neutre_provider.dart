import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/section_neutre.dart';
import '../../core/donnees/types.dart';

class SectionNeutreEntree {
  const SectionNeutreEntree({
    this.ib = 100,
    this.th3 = 20,
    this.triphase = true,
    this.cable = CableNeutre.multiconducteur,
    this.sectionPhase = 35,
    this.ame = Ame.cuivre,
    this.neutreProtege = false,
  });

  final double ib;

  /// Taux d'harmoniques de rang 3 en courant, en %.
  final double th3;
  final bool triphase;
  final CableNeutre cable;
  final double sectionPhase;
  final Ame ame;
  final bool neutreProtege;

  SectionNeutreEntree copyWith({
    double? ib,
    double? th3,
    bool? triphase,
    CableNeutre? cable,
    double? sectionPhase,
    Ame? ame,
    bool? neutreProtege,
  }) =>
      SectionNeutreEntree(
        ib: ib ?? this.ib,
        th3: th3 ?? this.th3,
        triphase: triphase ?? this.triphase,
        cable: cable ?? this.cable,
        sectionPhase: sectionPhase ?? this.sectionPhase,
        ame: ame ?? this.ame,
        neutreProtege: neutreProtege ?? this.neutreProtege,
      );
}

class SectionNeutreNotifier extends Notifier<SectionNeutreEntree> {
  @override
  SectionNeutreEntree build() => const SectionNeutreEntree();

  void modifier(SectionNeutreEntree Function(SectionNeutreEntree) f) =>
      state = f(state);
}

final sectionNeutreEntreeProvider =
    NotifierProvider<SectionNeutreNotifier, SectionNeutreEntree>(
        SectionNeutreNotifier.new);

final sectionNeutreResultatProvider = Provider<ResultatNeutre>((ref) {
  final e = ref.watch(sectionNeutreEntreeProvider);
  return calculerNeutre(
    ib: e.ib,
    th3Pourcent: e.th3,
    triphase: e.triphase,
    cable: e.cable,
    sectionPhase: e.sectionPhase,
    ame: e.ame,
    neutreProtege: e.neutreProtege,
  );
});
