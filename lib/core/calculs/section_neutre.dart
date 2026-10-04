/// Section du neutre avec harmoniques de rang 3.
///
/// NF C 15-100-1 (2024-08) : tableau 52.20 (détermination du courant d'emploi
/// du neutre en fonction du taux d'harmoniques de rang 3, TH3) et art. 524.2.3
/// (neutre de section réduite). Les formules sont celles du tableau ; le texte
/// de la norme n'est pas reproduit.
library;

import '../donnees/types.dart';

enum CableNeutre {
  multiconducteur('Câble multiconducteur'),
  monoconducteur('Câbles monoconducteurs');

  const CableNeutre(this.libelle);
  final String libelle;
}

/// Cas du tableau 52.20 selon TH3 (en %) : 1 (≤ 15), 2 (15 à 33), 3 (33 à 45),
/// 4 (> 45).
int casHarmoniques(double th3Pourcent) {
  if (th3Pourcent <= 15) return 1;
  if (th3Pourcent <= 33) return 2;
  if (th3Pourcent <= 45) return 3;
  return 4;
}

class ResultatNeutre {
  const ResultatNeutre({
    required this.cas,
    required this.courantPhase,
    required this.courantNeutre,
    required this.neutreEgalPhase,
    required this.neutreSuperieurPhase,
    required this.neutreReductibleAdmis,
    this.sectionNeutreMinimale,
  });

  /// Cas 1 à 4 du tableau 52.20.
  final int cas;

  /// Courant à retenir pour dimensionner les phases (A).
  final double courantPhase;

  /// Courant à retenir pour dimensionner le neutre (A). En cas 1, c'est la
  /// borne : le neutre transporte moins de IB/2 ([neutreReductibleAdmis]).
  final double courantNeutre;

  /// Neutre de même section que la phase (cas 2, câble multiconducteur 3 et 4).
  final bool neutreEgalPhase;

  /// Neutre de section supérieure à la phase (câbles monoconducteurs, cas 3 et
  /// 4).
  final bool neutreSuperieurPhase;

  /// Cas 1 : un neutre de section inférieure est admis si les conditions de
  /// l'art. 524.2.3 sont remplies.
  final bool neutreReductibleAdmis;

  /// Section minimale du neutre réduit (16 mm² Cu / 25 mm² Al), cas 1 admis.
  final double? sectionNeutreMinimale;
}

/// Section minimale d'un neutre réduit : 16 mm² en cuivre, 25 mm² en aluminium
/// (art. 524.2.3).
double sectionNeutreReduiteMinimale(Ame ame) =>
    ame == Ame.cuivre ? 16 : 25;

/// Courants de dimensionnement des phases et du neutre (tableau 52.20).
///
/// [ib] courant d'emploi du circuit (A), [th3Pourcent] taux d'harmoniques de
/// rang 3 en courant (%). En monophasé, le neutre transporte le courant de la
/// phase : seul le cas 1 existe au tableau. [sectionPhase], [ame] et
/// [neutreProtege] servent à vérifier l'art. 524.2.3 (neutre réduit) :
/// circuit triphasé, section de phase > 16 mm² Cu ou 25 mm² Al, cas 1 et
/// neutre protégé contre les surintensités.
ResultatNeutre calculerNeutre({
  required double ib,
  required double th3Pourcent,
  required bool triphase,
  required CableNeutre cable,
  required double sectionPhase,
  required Ame ame,
  required bool neutreProtege,
}) {
  if (!triphase) {
    return ResultatNeutre(
      cas: 1,
      courantPhase: ib,
      courantNeutre: ib,
      neutreEgalPhase: true,
      neutreSuperieurPhase: false,
      neutreReductibleAdmis: false,
    );
  }
  final th3 = th3Pourcent / 100;
  final cas = casHarmoniques(th3Pourcent);
  final mono = cable == CableNeutre.monoconducteur;
  switch (cas) {
    case 1:
      final seuil = ame == Ame.cuivre ? 16 : 25;
      final admis = sectionPhase > seuil && neutreProtege;
      return ResultatNeutre(
        cas: 1,
        courantPhase: ib,
        courantNeutre: ib / 2,
        neutreEgalPhase: !admis,
        neutreSuperieurPhase: false,
        neutreReductibleAdmis: admis,
        sectionNeutreMinimale: admis ? sectionNeutreReduiteMinimale(ame) : null,
      );
    case 2:
      return ResultatNeutre(
        cas: 2,
        courantPhase: ib / 0.86,
        courantNeutre: ib / 0.86,
        neutreEgalPhase: true,
        neutreSuperieurPhase: false,
        neutreReductibleAdmis: false,
      );
    case 3:
      final in3 = ib * th3 * 3 / 0.86;
      return ResultatNeutre(
        cas: 3,
        courantPhase: mono ? ib : in3,
        courantNeutre: in3,
        neutreEgalPhase: !mono,
        neutreSuperieurPhase: mono,
        neutreReductibleAdmis: false,
      );
    default:
      // Câble multiconducteur : IB × TH3 × 3 ; câbles monoconducteurs : le
      // coefficient 0,86 subsiste (tableau 52.20, cas 4).
      final in4 = mono ? ib * th3 * 3 / 0.86 : ib * th3 * 3;
      return ResultatNeutre(
        cas: 4,
        courantPhase: mono ? ib : in4,
        courantNeutre: in4,
        neutreEgalPhase: !mono,
        neutreSuperieurPhase: mono,
        neutreReductibleAdmis: false,
      );
  }
}
