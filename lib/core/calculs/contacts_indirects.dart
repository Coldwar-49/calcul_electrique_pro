/// Contacts indirects en TN et IT (visite périodique, méthode conventionnelle) :
/// longueur maximale de câble protégée par un disjoncteur ou un fusible.
///
/// Reprend les onglets « TN + IT avec M=1 », « TN + IT avec M>1 »,
/// « TN et IT Fusibles m=1 » et « TN et IT Fusibles m>1 ». Longueurs en mètres.
library;

import '../donnees/courbes_disjoncteurs.dart';
import '../donnees/fusibles.dart';
import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';
import 'ik_min.dart' show RegimeNeutre;

/// Table (tension, facteur) : le facteur de la plus grande tension <= saisie,
/// comme la fonction RECHERCHE du classeur.
typedef TableFacteurs = List<(double, double)>;

/// Facteur ITSN des disjoncteurs selon la tension entre phases.
const TableFacteurs facteurItsnDisjoncteur = [
  (220, 0.47),
  (400, 0.86),
  (690, 1.5),
  (1000, 2.17),
];

/// Facteur ITSN des fusibles selon la tension entre phases.
const TableFacteurs facteurItsnFusible = [
  (220, 0.47),
  (400, 0.86),
  (690, 1.25),
  (1000, 1.53),
];

/// Facteur TN des fusibles selon la tension phase / neutre.
const TableFacteurs facteurTnFusible = [
  (127, 0.55),
  (230, 1),
  (400, 1.45),
  (580, 1.78),
];

/// Recherche dans une table de facteurs. [ArgumentError] sous la 1re tension.
double rechercheFacteur(TableFacteurs table, double tension) {
  double? facteur;
  for (final (t, f) in table) {
    if (t <= tension) facteur = f;
  }
  if (facteur == null) {
    throw ArgumentError('Tension $tension V absente de la table');
  }
  return facteur;
}

/// Longueurs maximales selon le régime de neutre.
class LongueursMax {
  const LongueursMax({
    required this.tn,
    required this.itan,
    required this.itsn,
  });

  final double tn;
  final double itan;
  final double itsn;

  double pour(RegimeNeutre r) => switch (r) {
        RegimeNeutre.tn => tn,
        RegimeNeutre.itan => itan,
        RegimeNeutre.itsn => itsn,
      };
}

// ------------------------------------------------------------ disjoncteurs

/// Disjoncteur, Sph = Spe (m = 1) : M = 0,8 × U0 × S × n / (2 × ρ × Im/Ir × Ir).
///
/// [tensionPhN] et [tensionPhPh] : tensions phase/neutre et entre phases.
/// [section] est la section de phase (ou du neutre s'il est plus petit en ITAN).
LongueursMax longueurMaxDisjoncteurSphEgalSpe({
  required ReglageMagnetique reglage,
  required double ir,
  required double section,
  required int nbConducteurs,
  required Ame ame,
  required double tensionPhN,
  required double tensionPhPh,
}) {
  final tn = 0.8 *
      230 *
      (tensionPhN / 230) *
      corrigerSection(section) *
      nbConducteurs /
      (2 * rhoChuteTension(ame) * reglage.multiple * ir);
  return LongueursMax(
    tn: tn,
    itan: tn * 0.5,
    itsn: tn * rechercheFacteur(facteurItsnDisjoncteur, tensionPhPh),
  );
}

/// Disjoncteur, Sph ≠ Spe (m > 1) :
/// M = 0,8 × U0 / (ρ × Im/Ir × Ir × (1/(nph × Sph) + 1/(npe × Spe))).
LongueursMax longueurMaxDisjoncteurSphDiffSpe({
  required ReglageMagnetique reglage,
  required double ir,
  required double sectionPh,
  required int nbPh,
  required double sectionPe,
  required int nbPe,
  required Ame ame,
  required double tensionPhN,
  required double tensionPhPh,
}) {
  final tn = 0.8 *
      230 *
      (tensionPhN / 230) /
      (rhoChuteTension(ame) *
          reglage.multiple *
          ir *
          ((1 / (nbPh * corrigerSection(sectionPh))) +
              (1 / (nbPe * corrigerSection(sectionPe)))));
  return LongueursMax(
    tn: tn,
    itan: tn * 0.5,
    itsn: tn * rechercheFacteur(facteurItsnDisjoncteur, tensionPhPh),
  );
}

// ---------------------------------------------------------------- fusibles

/// Longueurs maximales pour un fusible : circuits terminaux et distribution.
class LongueursMaxFusible {
  const LongueursMaxFusible({
    required this.terminaux,
    required this.coefficientDistribution,
    required this.itsnNonFiable,
  });

  final LongueursMax terminaux;

  /// Coefficient appliqué pour les circuits de distribution.
  final double coefficientDistribution;

  /// true : la formule ITSN du classeur (Sph ≠ Spe) ne contient ni le courant
  /// de fusion Ia ni la section de phase ; son résultat est à vérifier.
  final bool itsnNonFiable;

  double distribution(RegimeNeutre r) =>
      terminaux.pour(r) * coefficientDistribution;
}

/// Fusible, Sph = Spe (m = 1) :
/// L = 0,8 × 230 × S × n × f / (2 × ρ × Ia). Distribution : × 1,88 (gG)
/// ou × 1,53 (aM).
LongueursMaxFusible longueurMaxFusibleSphEgalSpe({
  required TypeFusible type,
  required double calibre,
  required double section,
  required int nbConducteurs,
  required Ame ame,
  required double tensionPhN,
  required double tensionPhPh,
}) {
  final ia = courantIa(type, calibre);
  final s = corrigerSection(section);
  final rho = rhoChuteTension(ame);
  final fTn = rechercheFacteur(facteurTnFusible, tensionPhN);
  final fItsn = rechercheFacteur(facteurItsnFusible, tensionPhPh);
  final tn = 0.8 * 230 * s * nbConducteurs * fTn / (2 * rho * ia);
  return LongueursMaxFusible(
    terminaux: LongueursMax(
      tn: tn,
      itan: tn * 0.5,
      itsn: 0.8 * 230 * s * nbConducteurs * fItsn / (2 * rho * ia),
    ),
    coefficientDistribution: type.coefficientDivisionnaire,
    itsnNonFiable: false,
  );
}

/// Fusible, Sph ≠ Spe (m > 1).
///
/// Reproduit le classeur à l'identique, y compris deux points à vérifier :
/// - la formule ITSN est 0,8 × 230 × Spe × npe × f / (2 × ρ × nph), sans Ia ;
/// - le coefficient de distribution des aM est 1,88 (et non 1,53).
LongueursMaxFusible longueurMaxFusibleSphDiffSpe({
  required TypeFusible type,
  required double calibre,
  required double sectionPh,
  required int nbPh,
  required double sectionPe,
  required int nbPe,
  required Ame ame,
  required double tensionPhN,
  required double tensionPhPh,
}) {
  final ia = courantIa(type, calibre);
  final sph = corrigerSection(sectionPh);
  final spe = corrigerSection(sectionPe);
  final rho = rhoChuteTension(ame);
  final fTn = rechercheFacteur(facteurTnFusible, tensionPhN);
  final fItsn = rechercheFacteur(facteurItsnFusible, tensionPhPh);
  final tn = 0.8 *
      230 *
      fTn /
      (rho * ia * ((1 / (sph * nbPh)) + (1 / (spe * nbPe))));
  return LongueursMaxFusible(
    terminaux: LongueursMax(
      tn: tn,
      itan: tn * 0.5,
      itsn: 0.8 * 230 * spe * nbPe * fItsn / (2 * rho * nbPh),
    ),
    coefficientDistribution: 1.88,
    itsnNonFiable: true,
  );
}
