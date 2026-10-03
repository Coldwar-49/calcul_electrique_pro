/// Protection contre les contacts indirects en schéma TT par DDR :
/// Ra × IΔn ≤ UL, d'où Ra max = UL / IΔn.
/// UL = 50 V en général, 25 V dans certains locaux (valeurs à confirmer dans
/// l'article de la NF C 15-100 sur la protection par DDR en TT).
library;

enum TensionLimite {
  v50('50 V (cas général)', 50),
  v25('25 V (locaux particuliers)', 25);

  const TensionLimite(this.libelle, this.volts);
  final String libelle;
  final double volts;
}

class ResultatTT {
  const ResultatTT({
    required this.resistanceMax,
    required this.tensionDeContact,
    required this.conforme,
  });

  /// Résistance de prise de terre maximale en ohms.
  final double resistanceMax;

  /// Ra × IΔn en volts (null si Ra n'est pas renseignée).
  final double? tensionDeContact;

  /// null si Ra n'est pas renseignée.
  final bool? conforme;
}

/// [sensibilite] IΔn en ampères ; [resistanceTerre] Ra en ohms (facultative).
ResultatTT calculerProtectionTT({
  required double sensibilite,
  required double tensionLimite,
  double? resistanceTerre,
}) {
  final ramax = tensionLimite / sensibilite;
  final u = resistanceTerre == null ? null : resistanceTerre * sensibilite;
  return ResultatTT(
    resistanceMax: ramax,
    tensionDeContact: u,
    conforme: u == null ? null : u <= tensionLimite,
  );
}
