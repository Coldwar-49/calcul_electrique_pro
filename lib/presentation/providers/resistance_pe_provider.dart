import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/resistance_pe.dart';
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/fusibles.dart';

enum FamillePe {
  disjoncteur('Disjoncteur'),
  fusible('Fusible');

  const FamillePe(this.libelle);
  final String libelle;
}

enum TypeDisjoncteurPe {
  petit('Petit disjoncteur (courbe)'),
  industriel('Disjoncteur industriel (multiple de Ir)');

  const TypeDisjoncteurPe(this.libelle);
  final String libelle;
}

class ResistancePeEntree {
  const ResistancePeEntree({
    this.famille = FamillePe.disjoncteur,
    this.typeDisjoncteur = TypeDisjoncteurPe.petit,
    this.typeFusible = TypeFusible.gg,
    this.u0 = 230,
    this.rapportSphSpe = 1,
    this.courbe = CourbeDisjoncteur.c,
    this.multipleIr = 5,
    this.ir = 10,
    this.calibreFusible = 10,
    this.calcIn = 200,
    this.calcFacteur1 = 0.9,
    this.calcFacteur2 = 0.93,
  });

  final FamillePe famille;
  final TypeDisjoncteurPe typeDisjoncteur;
  final TypeFusible typeFusible;
  final double u0;
  final int rapportSphSpe;
  final CourbeDisjoncteur courbe;
  final double multipleIr;
  final double ir;
  final double calibreFusible;
  final double calcIn;
  final double calcFacteur1;
  final double calcFacteur2;

  double get irCalcule => calculerIr(
      courantNominal: calcIn, facteur1: calcFacteur1, facteur2: calcFacteur2);

  ResistancePeEntree copyWith({
    FamillePe? famille,
    TypeDisjoncteurPe? typeDisjoncteur,
    TypeFusible? typeFusible,
    double? u0,
    int? rapportSphSpe,
    CourbeDisjoncteur? courbe,
    double? multipleIr,
    double? ir,
    double? calibreFusible,
    double? calcIn,
    double? calcFacteur1,
    double? calcFacteur2,
  }) =>
      ResistancePeEntree(
        famille: famille ?? this.famille,
        typeDisjoncteur: typeDisjoncteur ?? this.typeDisjoncteur,
        typeFusible: typeFusible ?? this.typeFusible,
        u0: u0 ?? this.u0,
        rapportSphSpe: rapportSphSpe ?? this.rapportSphSpe,
        courbe: courbe ?? this.courbe,
        multipleIr: multipleIr ?? this.multipleIr,
        ir: ir ?? this.ir,
        calibreFusible: calibreFusible ?? this.calibreFusible,
        calcIn: calcIn ?? this.calcIn,
        calcFacteur1: calcFacteur1 ?? this.calcFacteur1,
        calcFacteur2: calcFacteur2 ?? this.calcFacteur2,
      );
}

class ResistancePeNotifier extends Notifier<ResistancePeEntree> {
  @override
  ResistancePeEntree build() => const ResistancePeEntree();

  void modifier(ResistancePeEntree Function(ResistancePeEntree) f) =>
      state = f(state);
}

final resistancePeEntreeProvider =
    NotifierProvider<ResistancePeNotifier, ResistancePeEntree>(
        ResistancePeNotifier.new);

class ResistancePeVue {
  const ResistancePeVue({
    this.terminaux,
    this.divisionnaires,
    this.ia,
    this.erreur,
  });

  final ResistancesPe? terminaux;

  /// Uniquement pour les fusibles.
  final ResistancesPe? divisionnaires;
  final double? ia;
  final String? erreur;
}

final resistancePeVueProvider = Provider<ResistancePeVue>((ref) {
  final e = ref.watch(resistancePeEntreeProvider);
  try {
    if (e.famille == FamillePe.fusible) {
      final r = resistanceMaxFusible(
        u0: e.u0,
        type: e.typeFusible,
        calibre: e.calibreFusible,
        rapportSphSpe: e.rapportSphSpe,
      );
      return ResistancePeVue(
          terminaux: r.terminaux, divisionnaires: r.divisionnaires, ia: r.ia);
    }
    final r = e.typeDisjoncteur == TypeDisjoncteurPe.petit
        ? resistanceMaxPetitDisjoncteur(
            u0: e.u0,
            courbe: e.courbe,
            ir: e.ir,
            rapportSphSpe: e.rapportSphSpe,
          )
        : resistanceMaxDisjoncteurIndustriel(
            u0: e.u0,
            multipleIr: e.multipleIr,
            ir: e.ir,
            rapportSphSpe: e.rapportSphSpe,
          );
    return ResistancePeVue(terminaux: r);
  } on ArgumentError catch (ex) {
    return ResistancePeVue(erreur: ex.message?.toString());
  }
});
