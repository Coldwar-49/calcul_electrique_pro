/// Bilan de puissance : P utilisée = Σ Pn × Ku × Ks.
/// Les coefficients Ku et Ks sont saisis par l'utilisateur ; aucune valeur
/// normative n'est figée (guide UTE C 15-105 à consulter).
library;

import 'courant_emploi.dart';

class LigneBilan {
  const LigneBilan({
    required this.nom,
    required this.puissance,
    this.ku = 1,
    this.ks = 1,
  });

  final String nom;

  /// Puissance installée Pn en watts.
  final double puissance;

  /// Coefficient d'utilisation (0 à 1).
  final double ku;

  /// Coefficient de simultanéité du circuit (0 à 1).
  final double ks;

  double get puissanceUtilisee => puissance * ku * ks;
}

class ResultatBilan {
  const ResultatBilan({
    required this.puissanceInstallee,
    required this.puissanceUtilisee,
    required this.puissanceApparente,
    required this.courantEmploi,
  });

  final double puissanceInstallee;
  final double puissanceUtilisee;

  /// S en VA = P utilisée / cos φ.
  final double puissanceApparente;
  final double courantEmploi;
}

/// [ksGlobal] s'applique à l'ensemble (foisonnement du tableau).
ResultatBilan calculerBilan({
  required List<LigneBilan> lignes,
  required double ksGlobal,
  required Alimentation alimentation,
  required double tension,
  required double cosPhi,
}) {
  var installee = 0.0;
  var utilisee = 0.0;
  for (final l in lignes) {
    installee += l.puissance;
    utilisee += l.puissanceUtilisee;
  }
  utilisee *= ksGlobal;
  return ResultatBilan(
    puissanceInstallee: installee,
    puissanceUtilisee: utilisee,
    puissanceApparente: utilisee / cosPhi,
    courantEmploi: courantEmploi(
      alimentation: alimentation,
      puissance: utilisee,
      tension: tension,
      cosPhi: cosPhi,
    ),
  );
}
