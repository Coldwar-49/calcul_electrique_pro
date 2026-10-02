import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/regle_triangle.dart';
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/types.dart';

/// Choix du réglage magnétique dans l'interface : une courbe ou un multiple de Ir.
enum ChoixReglage {
  b('Courbe B ou L', CourbeDisjoncteur.b),
  c('Courbe C ou U', CourbeDisjoncteur.c),
  d('Courbe D', CourbeDisjoncteur.d),
  k('Courbe K', CourbeDisjoncteur.k),
  ma('Courbe MA', CourbeDisjoncteur.ma),
  z('Courbe Z', CourbeDisjoncteur.z),
  multipleIr('Multiple de Ir (disjoncteur industriel)', null);

  const ChoixReglage(this.libelle, this.courbe);
  final String libelle;
  final CourbeDisjoncteur? courbe;
}

class TriangleEntree {
  const TriangleEntree({
    this.choixReglage = ChoixReglage.c,
    this.multipleIr = 8,
    this.ir = 63,
    this.sectionS1 = 10,
    this.ameS1 = Ame.cuivre,
    this.distancePS2 = 30,
    this.sectionS2 = 4,
    this.ameS2 = Ame.cuivre,
    this.longueurDistribuee = 10,
  });

  final ChoixReglage choixReglage;
  final double multipleIr;
  final double ir;
  final double sectionS1;
  final Ame ameS1;
  final double distancePS2;
  final double sectionS2;
  final Ame ameS2;
  final double longueurDistribuee;

  ReglageMagnetique get reglage => choixReglage.courbe != null
      ? ReglageMagnetique.courbe(choixReglage.courbe!)
      : ReglageMagnetique.multipleIr(multipleIr);

  TriangleEntree copyWith({
    ChoixReglage? choixReglage,
    double? multipleIr,
    double? ir,
    double? sectionS1,
    Ame? ameS1,
    double? distancePS2,
    double? sectionS2,
    Ame? ameS2,
    double? longueurDistribuee,
  }) =>
      TriangleEntree(
        choixReglage: choixReglage ?? this.choixReglage,
        multipleIr: multipleIr ?? this.multipleIr,
        ir: ir ?? this.ir,
        sectionS1: sectionS1 ?? this.sectionS1,
        ameS1: ameS1 ?? this.ameS1,
        distancePS2: distancePS2 ?? this.distancePS2,
        sectionS2: sectionS2 ?? this.sectionS2,
        ameS2: ameS2 ?? this.ameS2,
        longueurDistribuee: longueurDistribuee ?? this.longueurDistribuee,
      );
}

class TriangleNotifier extends Notifier<TriangleEntree> {
  @override
  TriangleEntree build() => const TriangleEntree();

  void modifier(TriangleEntree Function(TriangleEntree) f) => state = f(state);
}

final triangleEntreeProvider =
    NotifierProvider<TriangleNotifier, TriangleEntree>(TriangleNotifier.new);

final triangleResultatProvider = Provider<ResultatTriangle>((ref) {
  final e = ref.watch(triangleEntreeProvider);
  return calculerRegleTriangle(
    reglage: e.reglage,
    ir: e.ir,
    sectionS1: e.sectionS1,
    ameS1: e.ameS1,
    distancePS2: e.distancePS2,
    sectionS2: e.sectionS2,
    ameS2: e.ameS2,
    longueurDistribuee: e.longueurDistribuee,
  );
});
