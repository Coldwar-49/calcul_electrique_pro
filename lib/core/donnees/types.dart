/// Énumérations communes aux calculs (vocabulaire du classeur CLAUREG).
library;

/// Édition de la norme utilisée pour les tables.
///
/// `norme2013` = valeurs du classeur CLAUREG V3.6.
/// `normeActuelle` = valeurs de l'édition en vigueur. Tant qu'une valeur n'est
/// pas vérifiée dans une source officielle, elle reste celle de 2013
/// (voir docs/changements_nfc15100.md).
enum EditionNorme { norme2013, normeActuelle }

enum Ame { cuivre, aluminium }

enum Isolant { pvc, pr }

enum Circuit {
  monophase(2),
  triphase(3);

  const Circuit(this.nbConducteursCharges);
  final int nbConducteursCharges;
}

enum ModePose { b, c, d, e, f }

/// Type de câble (colonne AN du classeur) -> isolant (colonne AO).
const Map<String, Isolant> isolantParTypeCable = {
  'A05VV': Isolant.pvc,
  'A07RNF': Isolant.pvc,
  'CR1 (PR)': Isolant.pr,
  'CR1 (PVC)': Isolant.pvc,
  'FRN07': Isolant.pr,
  'H05VV': Isolant.pvc,
  'H07RNF': Isolant.pvc,
  'H07V': Isolant.pvc,
  'H07V2': Isolant.pr,
  'H07V3': Isolant.pvc,
  'H07Z': Isolant.pr,
  'Série FRN05': Isolant.pvc,
  'Série FR-N1': Isolant.pr,
  'Série H07B': Isolant.pr,
  'Série H07VV': Isolant.pvc,
  'U1000R2V': Isolant.pr,
  'U1000RGPFV': Isolant.pr,
  'U1000RVFV': Isolant.pr,
};
