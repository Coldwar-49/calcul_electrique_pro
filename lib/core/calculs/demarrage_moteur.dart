/// Démarrage des moteurs : intensité maximale de démarrage (tableau 55.3) et
/// puissance maximale des moteurs alimentés directement (tableau 55.4),
/// NF C 15-100-1 (2024-08), partie 5-55.
///
/// Les lignes sont les deux catégories du tableau : locaux d'habitation
/// (branchement à puissance limitée) et autres locaux (branchement à puissance
/// surveillée). L'intitulé exact des lignes n'a pas pu être extrait du PDF :
/// à relire (voir docs/changements_nfc15100.md).
library;

enum AlimentationMoteur {
  monophase('Monophasé 230 V'),
  triphase('Triphasé 400 V');

  const AlimentationMoteur(this.libelle);
  final String libelle;
}

enum LocalMoteur {
  habitation('Locaux d\'habitation (branchement à puissance limitée)'),
  autres('Autres locaux (branchement à puissance surveillée)');

  const LocalMoteur(this.libelle);
  final String libelle;
}

enum ReseauMoteur {
  aerien('Réseau aérien'),
  souterrain('Réseau souterrain');

  const ReseauMoteur(this.libelle);
  final String libelle;
}

enum ModeDemarrage {
  direct('Démarrage direct à pleine puissance'),
  autre('Autre mode de démarrage');

  const ModeDemarrage(this.libelle);
  final String libelle;
}

/// Intensité maximale de démarrage (A), tableau 55.3.
double intensiteDemarrageMax(
  AlimentationMoteur alimentation,
  LocalMoteur local,
  ReseauMoteur reseau,
) {
  final mono = alimentation == AlimentationMoteur.monophase;
  if (local == LocalMoteur.habitation) return mono ? 45 : 60;
  final aerien = reseau == ReseauMoteur.aerien;
  return mono ? (aerien ? 100 : 200) : (aerien ? 125 : 250);
}

/// Puissance maximale (kVA) d'un moteur alimenté directement, tableau 55.4.
/// En monophasé, [mode] est sans effet.
double puissanceMoteurMax(
  AlimentationMoteur alimentation,
  LocalMoteur local,
  ReseauMoteur reseau,
  ModeDemarrage mode,
) {
  final mono = alimentation == AlimentationMoteur.monophase;
  if (local == LocalMoteur.habitation) {
    return mono ? 1.4 : (mode == ModeDemarrage.direct ? 5.5 : 11);
  }
  final aerien = reseau == ReseauMoteur.aerien;
  if (mono) return aerien ? 3 : 5.5;
  return mode == ModeDemarrage.direct
      ? (aerien ? 11 : 22)
      : (aerien ? 22 : 45);
}

class ResultatDemarrage {
  const ResultatDemarrage({
    required this.intensiteMax,
    required this.puissanceMax,
    this.intensiteConforme,
    this.puissanceConforme,
  });

  final double intensiteMax;
  final double puissanceMax;

  /// null si la valeur correspondante n'est pas renseignée.
  final bool? intensiteConforme;
  final bool? puissanceConforme;
}

ResultatDemarrage verifierDemarrage({
  required AlimentationMoteur alimentation,
  required LocalMoteur local,
  required ReseauMoteur reseau,
  required ModeDemarrage mode,
  double? intensiteDemarrage,
  double? puissanceKva,
}) {
  final id = intensiteDemarrageMax(alimentation, local, reseau);
  final p = puissanceMoteurMax(alimentation, local, reseau, mode);
  return ResultatDemarrage(
    intensiteMax: id,
    puissanceMax: p,
    intensiteConforme:
        intensiteDemarrage == null ? null : intensiteDemarrage <= id,
    puissanceConforme: puissanceKva == null ? null : puissanceKva <= p,
  );
}
