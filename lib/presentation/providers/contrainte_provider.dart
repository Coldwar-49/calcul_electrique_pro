import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/contrainte_thermique.dart';
import '../../core/donnees/contrainte_thermique.dart';
import '../../core/donnees/types.dart';

enum Protection { fusible, disjoncteur }

class ContrainteEntree {
  const ContrainteEntree({
    this.protection = Protection.fusible,
    this.sectionPh = 16,
    this.sectionN = 16,
    this.ame = Ame.cuivre,
    this.canalisation = CanalisationPe.meme,
    this.isolant = IsolantContrainte.prEpr,
    this.u0 = 230,
    this.longueur = 70,
    this.ikKa = 10,
    this.edition = EditionNorme.normeActuelle,
  });

  final Protection protection;
  final double sectionPh;
  final double sectionN;
  final Ame ame;
  final CanalisationPe canalisation;
  final IsolantContrainte isolant;
  final double u0;
  final double longueur;
  final double ikKa;

  /// Édition des valeurs de k : 2024 ou classeur 2013.
  final EditionNorme edition;

  ContrainteEntree copyWith({
    Protection? protection,
    double? sectionPh,
    double? sectionN,
    Ame? ame,
    CanalisationPe? canalisation,
    IsolantContrainte? isolant,
    double? u0,
    double? longueur,
    double? ikKa,
    EditionNorme? edition,
  }) {
    final nouvelleCanalisation = canalisation ?? this.canalisation;
    var nouvelIsolant = isolant ?? this.isolant;
    // Le PE nu n'existe pas si le PE est dans la même canalisation.
    if (!isolantsContrainte(nouvelleCanalisation).contains(nouvelIsolant)) {
      nouvelIsolant = IsolantContrainte.prEpr;
    }
    return ContrainteEntree(
      protection: protection ?? this.protection,
      sectionPh: sectionPh ?? this.sectionPh,
      sectionN: sectionN ?? this.sectionN,
      ame: ame ?? this.ame,
      canalisation: nouvelleCanalisation,
      isolant: nouvelIsolant,
      u0: u0 ?? this.u0,
      longueur: longueur ?? this.longueur,
      ikKa: ikKa ?? this.ikKa,
      edition: edition ?? this.edition,
    );
  }
}

class ContrainteNotifier extends Notifier<ContrainteEntree> {
  @override
  ContrainteEntree build() => const ContrainteEntree();

  void modifier(ContrainteEntree Function(ContrainteEntree) f) =>
      state = f(state);
}

final contrainteEntreeProvider =
    NotifierProvider<ContrainteNotifier, ContrainteEntree>(
        ContrainteNotifier.new);

class ContrainteVue {
  const ContrainteVue({required this.k, this.resultat, this.erreur});

  final double k;
  final ResultatContrainte? resultat;
  final String? erreur;
}

final contrainteVueProvider = Provider<ContrainteVue>((ref) {
  final e = ref.watch(contrainteEntreeProvider);
  try {
    final k = kContrainteThermique(
      e.ame,
      e.isolant,
      e.canalisation,
      edition: e.edition,
    );
    final r = e.protection == Protection.fusible
        ? calculerContrainteFusible(
            sectionPh: e.sectionPh,
            sectionN: e.sectionN,
            ame: e.ame,
            u0: e.u0,
            longueur: e.longueur,
            k: k,
          )
        : calculerContrainteDisjoncteur(
            sectionPh: e.sectionPh,
            sectionN: e.sectionN,
            ikKa: e.ikKa,
            k: k,
          );
    return ContrainteVue(k: k, resultat: r);
  } on ArgumentError catch (ex) {
    return ContrainteVue(k: 0, erreur: ex.message?.toString());
  }
});
