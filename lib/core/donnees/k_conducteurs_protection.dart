/// Valeurs de k des conducteurs de protection, NF C 15-100-1 (2024-08),
/// partie 5-54, tableaux 54A.2A, 54A.2B, 54A.3A, 54A.3B, 54A.4, 54A.6A et
/// 54A.6B (cuivre et aluminium ; l'acier n'est pas repris).
///
/// Non repris : tableau 54A.5 (gaine métallique d'un câble), lecture du PDF
/// ambiguë. Les valeurs de ces tableaux diffèrent de celles du guide UTE
/// C 15-106 (2003) et du classeur CLAUREG (voir docs/changements_nfc15100.md).
library;

import 'types.dart';

/// Une ligne de tableau : k pour le cuivre et l'aluminium.
///
/// Pour les conducteurs isolés, la norme donne deux valeurs « a/b » : la plus
/// faible ([cuGros], [alGros]) s'applique aux sections supérieures à 300 mm².
class LigneK {
  const LigneK(this.libelle, this.cu, this.al, {this.cuGros, this.alGros});

  final String libelle;
  final double cu;
  final double al;

  /// Valeur pour une section > 300 mm² (null si la ligne n'en a pas).
  final double? cuGros;
  final double? alGros;

  double k(Ame ame, {bool gros = false}) => ame == Ame.cuivre
      ? (gros ? cuGros ?? cu : cu)
      : (gros ? alGros ?? al : al);
}

/// Situation du conducteur de protection (tableau de la norme).
enum SituationPe {
  incorpore('Dans le câble ou regroupé avec d\'autres câbles (54A.4)'),
  isoleSepare('Isolé, séparé, non enterré (54A.2A)'),
  isoleSepareEnterre('Isolé, séparé, enterré (54A.2B)'),
  nuSurGaine('Nu, sur la gaine d\'un câble, non enterré (54A.3A)'),
  nuSurGaineEnterre('Nu, sur la gaine d\'un câble, enterré (54A.3B)'),
  nuNonEnterre('Nu, non enterré (54A.6A)'),
  nuEnterre('Nu, enterré (54A.6B)');

  const SituationPe(this.libelle);
  final String libelle;
}

const _pvc70 = 'PVC 70 °C';
const _pvc90 = 'PVC 90 °C';
const _epr = 'PR / EPR 90 °C';
const _cao60 = 'Caoutchouc 60 °C';
const _cao85 = 'Caoutchouc 85 °C';
const _sil = 'Caoutchouc silicone';

const List<LigneK> _tableau54A4 = [
  LigneK(_pvc70, 111, 75, cuGros: 99, alGros: 67),
  LigneK(_pvc90, 96, 65, cuGros: 82, alGros: 55),
  LigneK(_epr, 138, 93),
  LigneK(_cao60, 136, 91),
  LigneK(_cao85, 130, 87),
  LigneK(_sil, 128, 86),
];

const List<LigneK> _tableau54A2A = [
  LigneK(_pvc70, 138, 93, cuGros: 128, alGros: 87),
  LigneK(_pvc90, 138, 93, cuGros: 128, alGros: 87),
  LigneK(_epr, 169, 114),
  LigneK(_cao60, 153, 103),
  LigneK(_cao85, 160, 108),
  LigneK(_sil, 194, 130),
];

const List<LigneK> _tableau54A2B = [
  LigneK(_pvc70, 144, 97, cuGros: 135, alGros: 91),
  LigneK(_pvc90, 144, 97, cuGros: 135, alGros: 91),
  LigneK(_epr, 175, 118),
  LigneK(_cao60, 159, 107),
  LigneK(_cao85, 166, 112),
  LigneK(_sil, 199, 134),
];

// Nature de la gaine du câble avec lequel le conducteur nu est en contact.
const List<LigneK> _tableau54A3A = [
  LigneK('Gaine PVC', 153, 103),
  LigneK('Gaine PR / EPR', 133, 90),
  LigneK('Gaine caoutchouc silicone', 160, 108),
];

const List<LigneK> _tableau54A3B = [
  LigneK('Gaine PVC', 159, 107),
  LigneK('Gaine PR / EPR', 140, 94),
  LigneK('Gaine caoutchouc silicone', 166, 112),
];

const List<LigneK> _tableau54A6A = [
  LigneK('Visible et dans des zones restreintes', 220, 123),
  LigneK('Conditions normales', 153, 103),
  LigneK('Risque d\'incendie', 133, 90),
];

const List<LigneK> _tableau54A6B = [
  LigneK('Visible et dans des zones restreintes', 224, 126),
  LigneK('Conditions normales', 159, 107),
  LigneK('Risque d\'incendie', 140, 94),
];

/// Lignes proposées pour une situation du PE.
List<LigneK> lignesK(SituationPe situation) => switch (situation) {
      SituationPe.incorpore => _tableau54A4,
      SituationPe.isoleSepare => _tableau54A2A,
      SituationPe.isoleSepareEnterre => _tableau54A2B,
      SituationPe.nuSurGaine => _tableau54A3A,
      SituationPe.nuSurGaineEnterre => _tableau54A3B,
      SituationPe.nuNonEnterre => _tableau54A6A,
      SituationPe.nuEnterre => _tableau54A6B,
    };

/// Lignes du tableau 54A.4, utilisées pour k1 (conducteur de phase).
List<LigneK> lignesKPhase() => _tableau54A4;

/// Libellé de la ligne [indice] d'une situation (borné à la liste).
LigneK ligneK(SituationPe situation, int indice) {
  final l = lignesK(situation);
  return l[indice.clamp(0, l.length - 1)];
}
