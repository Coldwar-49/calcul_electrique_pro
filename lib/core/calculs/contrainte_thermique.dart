/// Vérification de la contrainte thermique des conducteurs actifs.
library;

import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

/// Limite du critère « T ≤ 5 s » du classeur.
const double tempsLimite = 5;

/// Facteur de réactance du classeur (cellules I9 et J9).
///
/// Reproduit la cellule à l'identique : S ≤ 150 -> 1, 185 -> 1,2,
/// 240 -> 1,25, S ≥ 300 -> 1,3. Les autres sections (entre 150 et 300, hors
/// 185 et 240) n'ont pas de valeur dans le classeur : [ArgumentError].
double facteurReactance(double section) {
  if (section <= 150) return 1;
  if (section == 185) return 1.2;
  if (section == 240) return 1.25;
  if (section >= 300) return 1.3;
  throw ArgumentError('Section $section mm² sans facteur de réactance');
}

class ResultatContrainte {
  const ResultatContrainte({
    required this.sectionRetenue,
    required this.temps,
    required this.conforme,
    this.ikMin,
  });

  /// Plus petite des sections phase / neutre (mm²).
  final double sectionRetenue;

  /// T = (k × S)² / I², en secondes.
  final double temps;

  /// T ≤ 5 s.
  final bool conforme;

  /// Ik min en ampères (protection par fusible uniquement).
  final double? ikMin;
}

double _sectionRetenue(double sPh, double sN) => sPh <= sN ? sPh : sN;

double _temps(double k, double section, double iAmperes) =>
    ((k * section) * (k * section)) / (iAmperes * iAmperes);

/// Ik min (A) d'une canalisation : 0,8 × U0 / (ρ × L × (Xph/Sph + Xn/Sn)).
double ikMinFusible({
  required double sectionPh,
  required double sectionN,
  required Ame ame,
  required double u0,
  required double longueur,
}) =>
    (0.8 * u0) /
    (rhoContrainteThermique(ame) *
        longueur *
        ((facteurReactance(sectionPh) / sectionPh) +
            (facteurReactance(sectionN) / sectionN)));

/// Protection par fusible : Ik min calculé, puis T.
ResultatContrainte calculerContrainteFusible({
  required double sectionPh,
  required double sectionN,
  required Ame ame,
  required double u0,
  required double longueur,
  required double k,
}) {
  final ik = ikMinFusible(
    sectionPh: sectionPh,
    sectionN: sectionN,
    ame: ame,
    u0: u0,
    longueur: longueur,
  );
  final s = _sectionRetenue(sectionPh, sectionN);
  final t = _temps(k, s, ik);
  return ResultatContrainte(
    sectionRetenue: s,
    temps: t,
    conforme: t <= tempsLimite,
    ikMin: ik,
  );
}

/// Protection par disjoncteur : T avec la valeur maximale d'Ik saisie (kA).
ResultatContrainte calculerContrainteDisjoncteur({
  required double sectionPh,
  required double sectionN,
  required double ikKa,
  required double k,
}) {
  final s = _sectionRetenue(sectionPh, sectionN);
  final t = _temps(k, s, ikKa * 1000);
  return ResultatContrainte(
    sectionRetenue: s,
    temps: t,
    conforme: t <= tempsLimite,
  );
}
